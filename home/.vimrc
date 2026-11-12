" ~/.vimrc — system clipboard for plain terminal vim on Wayland (Hyprland).
"
" This vim build has +clipboard_provider but no X11/Wayland clipboard compiled
" in, so the "+ / "* registers do nothing out of the box. Vim 9.2's clipboard
" provider feature routes them through wl-clipboard (wl-copy / wl-paste) —
" the same tools Neovim uses. With this in place:
"
"   yy / dd / p          behave like every other app (clipboard=unnamedplus)
"   "+yy / "+p           still work explicitly
"
" Notes for anyone editing this file later:
"   * The provider name must NOT be "wayland" or "x11" — those collide with
"     vim's built-in 'clipmethod' entries and silently never get used.
"   * v:clipmethod is read-only; assigning it raises E46 and (being an error
"     mid-vimrc) aborts the rest of the file. Registering the provider in
"     'clipmethod' is enough — vim picks the first available entry itself.
"   * Keep the wl-copy command free of shell metacharacters. Passing
"     "--type text/plain;charset=utf-8" looks innocent, but the ';' is read
"     by sh as a command separator and makes vim's system() blow up with
"     "E282: Cannot read from ..." — wl-copy's stdin default is already
"     text/plain;charset=utf-8, so no --type is needed.
"   * Neovim needs none of this: nvim auto-uses wl-copy when it finds it.

if !exists('g:wayland_clipboard_loaded')
    let g:wayland_clipboard_loaded = 1

    func! s:wl_available() abort
        " Only offer the provider inside a Wayland session with the tools present.
        return executable('wl-copy') && executable('wl-paste')
              \ && (!empty($WAYLAND_DISPLAY) || $XDG_SESSION_TYPE ==# 'wayland')
    endfunc

    func! s:wl_copy(reg, type, lines) abort
        let l:text = join(a:lines, "\n")
        " Linewise (and, approximately, blockwise) selections keep their
        " trailing newline so pasting into other apps behaves like a normal copy.
        if a:type !=# 'v' && !empty(l:text)
            let l:text .= "\n"
        endif
        try
            " :silent keeps terminal focus-event noise off the screen
            " (:h clipboard-providers-copy).
            silent! call system('wl-copy', l:text)
        catch
        endtry
    endfunc

    func! s:wl_paste(reg) abort
        let l:text = ''
        try
            let l:text = system('wl-paste --no-newline')
            if v:shell_error != 0
                return []  " no selection — leave the register untouched
            endif
        catch
            return []
        endtry
        if l:text =~# "\n$"
            " Selection ends with a newline -> linewise register.
            return ['V', split(l:text, "\n", 1)[0:-2]]
        endif
        return ['v', [l:text]]
    endfunc

    let v:clipproviders['waylandclip'] = {
        \ 'available': function('s:wl_available'),
        \ 'copy':      {'*': function('s:wl_copy'), '+': function('s:wl_copy')},
        \ 'paste':     {'*': function('s:wl_paste'), '+': function('s:wl_paste')},
        \ }

    set clipmethod^=waylandclip
    set clipboard^=unnamedplus
endif
