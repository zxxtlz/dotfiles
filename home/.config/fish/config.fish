source /usr/share/cachyos-fish-config/cachyos-config.fish

# User-local binaries (shell-switch, etc.)
fish_add_path --global --prepend "$HOME/.local/bin"

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# --- Single-line prompt: user@hostname + current path on the input line ---
# Overrides the 'pure' vendor prompt (which puts the path on a separate line).
function fish_prompt --description 'Write out the prompt'
    set -l last_status $status
    set -l user_color (set_color -o green)
    set -l path_color (set_color -o brblue)
    set -l symbol_color (set_color brgreen)
    test $last_status -ne 0; and set symbol_color (set_color brred)
    set -l normal (set_color normal)

    echo -n "$user_color"(whoami)"@"(hostname -s)"$normal "
    echo -n "$path_color"(prompt_pwd)"$normal "
    echo -n "$symbol_color❯ $normal"
end

# --- pacman falls back to the AUR via yay when a package is not in the repos ---
# Sync/install/search/info operations go through yay (repos first, then AUR).
# Everything else (removal, queries, cache, etc.) uses the real pacman.
function pacman --description 'pacman with AUR fallback via yay'
    set -l use_yay false
    for arg in $argv
        switch $arg
            case '-S' '-S*' '--sync' '-Si' '-Sii' '-Ss' '-Sl' '-Sw' '-Sc' '-Scc'
                set use_yay true
                break
        end
    end
    if test $use_yay = true
        command yay $argv
    else
        command /usr/bin/pacman $argv
    end
end
