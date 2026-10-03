-- Finishes the neovim install during the image build, so that the first nvim
-- in a fresh cell opens an editor instead of an installer.
--
-- LazyVim does this work on startup and asynchronously: mason begins installing
-- its tools, treesitter compiles parsers. A headless nvim that runs +qa exits
-- while both are in flight and kills them, which is why this waits instead.

local timeout = tonumber(vim.env.SOLITARY_NVIM_TIMEOUT or "900") * 1000
local failed = {}

local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")

-- The lists live in the plugin specs, so they follow the config rather than
-- being repeated here and going stale.
local function opts_of(name)
	local plugin = Config.plugins[name]
	return plugin and Plugin.values(plugin, "opts", false) or {}
end

local function log(msg)
	io.stdout:write("bootstrap: " .. msg .. "\n")
	io.stdout:flush()
end

-- Mason. Its installs are already running by the time this executes, or will be
-- once the registry is in: LazyVim asks for it asynchronously, and on a fresh
-- build there is none yet, so until it lands every get_package below fails.
-- refresh() without a callback blocks, and joins the update already in flight
-- rather than starting a second one.
local registry = require("mason-registry")
if not registry.refresh() then
	log("FAILED: could not download mason's registry")
	vim.cmd("cq")
end
-- The tree-sitter CLI is not among them: the image installs it before nvim
-- first runs, so LazyVim finds it on PATH and never asks mason for it.
local tools = vim.deepcopy(opts_of("mason.nvim").ensure_installed or {})

-- LazyVim starts its own list on startup; ask for whatever is still missing.
log("installing mason tools: " .. table.concat(tools, ", "))
for _, name in ipairs(tools) do
	local ok, pkg = pcall(registry.get_package, name)
	if ok and not pkg:is_installed() and not pkg:is_installing() then
		pcall(function()
			pkg:install()
		end)
	end
end

-- Wait for the installs to finish rather than to succeed: one that failed is
-- neither installed nor installing, and waiting on it would only spend the
-- timeout before reporting it.
vim.wait(timeout, function()
	for _, name in ipairs(tools) do
		local ok, pkg = pcall(registry.get_package, name)
		if ok and pkg:is_installing() then
			return false
		end
	end
	return true
end, 1000)

-- A name the registry does not know is a failure too, not something to skip.
for _, name in ipairs(tools) do
	local ok, pkg = pcall(registry.get_package, name)
	if not ok or not pkg:is_installed() then
		failed[#failed + 1] = "mason/" .. name
	end
end

-- The parsers below are compiled by the tree-sitter CLI, so without it they
-- can only fail, and say less about why than this does.
if vim.fn.executable("tree-sitter") ~= 1 then
	failed[#failed + 1] = "tree-sitter CLI (not on PATH)"
	log("FAILED: " .. table.concat(failed, ", "))
	vim.cmd("cq")
end

-- Treesitter parsers, compiled here rather than on first open.
local langs = opts_of("nvim-treesitter").ensure_installed or {}
log("installing " .. #langs .. " treesitter parsers")

local ts = require("nvim-treesitter")
local ok, handle = pcall(ts.install, langs)
if ok and type(handle) == "table" and handle.wait then
	pcall(function()
		handle:wait(timeout)
	end)
else
	vim.wait(timeout, function()
		return #ts.get_installed() >= #langs
	end, 2000)
end

local installed = ts.get_installed()
log(("mason tools: %d/%d, parsers: %d/%d"):format(#tools - #failed, #tools, #installed, #langs))

-- A parser or tool that will not install is worth failing the build over: the
-- point of this step is that a cell needs no network to start working.
if #installed < #langs then
	failed[#failed + 1] = ("parsers (%d of %d)"):format(#installed, #langs)
end

if #failed > 0 then
	log("FAILED: " .. table.concat(failed, ", "))
	vim.cmd("cq")
end

vim.cmd("qa!")
