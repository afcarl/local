func! ToggleFont() 
    if !exists("g:togfont") 
        let g:togfont=1
    else 
        let g:togfont = 1 - g:togfont 
    endif 
    if (g:togfont)
        :call SetFontMonoDyslexic()
    else 
        :call SetFontDefault()
    endif 
endfu 

" Setting Font Functions
fu! SetFontMonoDyslexic()
    if has("win32") || has("win16")
        set gfn=Mono\ Dyslexic:h11
    else
        set guifont=MonoDyslexic
    endif
endfu

fu! SetFontDefault()
    if has("win32") || has("win16")
        set gfn=Fixedsys:h9
    else
        set guifont=Monospace
    endif
endfu

function! FontDecrease()
    call AdjustFontSize(-1)
endfunction
command! FontDecrease call FontDecrease()


function! FontIncrease()
    call AdjustFontSize(1)
endfunction
command! FontIncrease call FontIncrease()

" NEW QUICK INCREASE FONT STUFF
function! AdjustFontSize(amount)
    "                     part1       part2      part3
    let font_pattern = '^\(.*\):h\([0-9][0-9]*\)\(.*$\)'
    let min_sz = 6
    let max_sz = 16
    if has("gui_running")
        let oldfont = substitute(&guifont, font_pattern, '\1', '')
        let cursize = substitute(&guifont, font_pattern, '\2', '')
        let newsize = cursize + a:amount
        if (newsize >= min_sz) && (newsize <= max_sz)
            let newfont = oldfont . ':h' . newsize
            let &guifont = newfont
        endif
    else
        echoerr "This only works in a gui"
    endif
endfunction

