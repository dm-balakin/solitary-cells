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

-- Mason. Its installs are already running by the time this executes.
local registry = require("mason-registry")
local tools = vim.list_extend(
	-- treesitter's main branch compiles parsers with the tree-sitter CLI,
	-- which mason installs but no config lists.
	{ "tree-sitter-cli" },
	vim.deepcopy(opts_of("mason.nvim").ensure_installed or {})
)

-- LazyVim starts its own list on startup, but nothing asks for the tree-sitter
-- CLI until a parser is compiled, so ask for whatever is still missing.
log("installing mason tools: " .. table.concat(tools, ", "))
for _, name in ipairs(tools) do
	local ok, pkg = pcall(registry.get_package, name)
	if ok and not pkg:is_installed() then
		pcall(function()
			pkg:install()
		end)
	end
end

vim.wait(timeout, function()
	for _, name in ipairs(tools) do
		local ok, pkg = pcall(registry.get_package, name)
		if ok and not pkg:is_installed() then
			return false
		end
	end
	return true
end, 1000)

for _, name in ipairs(tools) do
	local ok, pkg = pcall(registry.get_package, name)
	if ok and not pkg:is_installed() then
		failed[#failed + 1] = "mason/" .. name
	end
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
