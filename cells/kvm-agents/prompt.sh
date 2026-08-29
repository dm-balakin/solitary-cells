# Installed as /etc/profile.d/solitary-prompt.sh and sourced from
# /etc/bash.bashrc, because solitary opens a non-login shell.
#
# The prompt answers three questions at a glance: which cell this is, where in
# it you are, and what git thinks. Catppuccin Mocha colours, to agree with tmux.

# Dirty state only. Untracked scanning is the expensive walk, and this runs on
# every prompt.
GIT_PS1_SHOWDIRTYSTATE=1
if [ -r /usr/lib/git-core/git-sh-prompt ]; then
	. /usr/lib/git-core/git-sh-prompt
else
	__git_ps1() { :; }
fi

# A cell is not the host, and the prompt should never let you forget it: the
# name comes from solitary, which sets SOLITARY_CELL when it starts the
# container.
__solitary_prompt() {
	local rc=$? cell path git branch flags caret

	cell=${SOLITARY_CELL:-cell}
	path=${PWD/#"$HOME"/\~}

	# git-sh-prompt distinguishes staged from unstaged from stashed. Which
	# kind of dirty it is belongs in git status, not in every line of the
	# terminal: one mark for "there is something to commit".
	git=$(__git_ps1 '%s' 2>/dev/null)
	branch=${git%% *}
	flags=${git#"$branch"}
	case $flags in
		*[*+%$#]*) flags='*' ;;
		*) flags= ;;
	esac
	branch=${branch:+ $branch$flags}

	# \001 and \002 rather than \[ \]: PS1 is assigned inside a function,
	# where the bracket form is not parsed and would print literally.
	local mauve=$'\001\e[38;2;203;166;247m\002' \
	      blue=$'\001\e[38;2;137;180;250m\002' \
	      dim=$'\001\e[38;2;127;132;156m\002' \
	      green=$'\001\e[38;2;166;227;161m\002' \
	      red=$'\001\e[38;2;243;139;168m\002' \
	      off=$'\001\e[0m\002'

	if [ "$rc" -eq 0 ]; then caret=$green; else caret=$red; fi

	# The terminal's title, which is what tmux shows as the pane title and
	# what this config renders in the window pill. Ubuntu sets one from its
	# own PROMPT_COMMAND; this prompt replaces that, so it has to set its own
	# or the pill goes blank.
	case $TERM in
		xterm*|rxvt*|tmux*|screen*|alacritty|foot*|wezterm|ghostty*)
			printf '\033]0;%s\007' "$cell:$path"
			;;
	esac

	PS1="${mauve}◆ ${cell}${off} ${blue}${path}${off}${dim}${branch}${off} ${caret}❯${off} "
}
PROMPT_COMMAND=__solitary_prompt

# A cell is long-lived and its history is the record of what was done in it.
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
