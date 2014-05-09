" ========= VIM PREFERENCES ========= "

" Some of these probably need to be cleaned up
syntax on
filetype plugin indent on
" MISC: win clipboard on linux
if has("win32") || has("win16")
    behave mswin
else
    source $VIMRUNTIME/mswin.vim
endif

" " Turn backup off, since most stuff is in SVN, git et.c anyway...
set ff=unix
set ffs=unix,dos
if has("win32") || has("win16")
    " WINDOWS COMMANDS
    "set guioptions+=b guioptions-=e guioptions-=L guioptions? guioptions=grtb
    set backupdir=D:/sys/vim_tmp/
    set undodir=D:/sys/vim_tmp/
else
    " LINUX COMMANDS
    set backupdir=/media/Store/sys/vim_tmp/
    set undodir=/media/Store/sys/vim_tmp/
endif
set nobackup
set autochdir

set nomousehide
set nowb
set noswapfile
" Do not open these sort of files
set wildignore=*.o,*~,*.pyc,*.aux,*.masv,*.bbl,*.bcf,*.blg,*.brf,*.synctex,*.upa,*.upb,*.pdf,*.dvi

set wildmode=longest,list,full
set wildmenu

" MISC: win clipboard on linux
if has("win32") || has("win16")
else
    set clipboard=unnamedplus
endif

set shellslash
set grepprg=grep\ -nH\ $*


if has("gui_running")
    "colorscheme murphy
    colorscheme synic
endif
set shiftwidth=4
set tabstop=4
set expandtab
set cino={1s
set autoread
set lbr " Linebreak on 500 characters
set tw=500

" Vim: Gray Line Numbering
:set nu 
if has("gui_running")
    :highlight LineNr guifg=#333333
    " Cross platform fonts
    if has("win32") || has("win16")
        :highlight LineNr font='Fixedsys'
    else
        :highlight LineNr font='Monospace'
    endif
endif

"-------------------------

"Windows symlink problems
set bkc=yes
set nobackup 
set nowritebackup

hi StatusLine ctermbg=red ctermfg=green
hi StatusLine guibg=gray10 guifg=green

" why wont this work
highlight Cursor guifg=blue guibg=orange

" Set the default font to mono dyslexic size 11
:call SetFontMonoDyslexic()