" Refererences:  http://stackoverflow.com/questions/23486512/how-can-i-augment-an-existing-set-of-syntax-rules-for-a-filetype-in-vim-withou


" http://vim.wikia.com/wiki/Identify_the_syntax_highlighting_group_used_at_the_cursor
" Show syntax highlight group at cursor
" synIDattr(synID(line("."),col("."),1),"name")

" DUPLICATED FROM $VIMRUNTIME/syntax/tex.vim
"let s:tex_fast= "bcmMprsSvV"
"if exists("g:tex_fast")
" if type(g:tex_fast) != 1
"  let s:tex_fast= ""
" else
"  let s:tex_fast= g:tex_fast
" endif
" let s:tex_no_error= 1
"else
" let s:tex_fast= "bcmMprsSvV"
"endif/


" + -----------------------------
" from $VIMRUNTIME/syntax/vim.vim
" [-- python --] {{{3
"let s:pythonpath= fnameescape(expand("<sfile>:p:h")."/python.vim")
let s:pythonpath= fnameescape(expand("$VIMRUNTIME/syntax/")."/python.vim")
if !filereadable(s:pythonpath)
 for s:pythonpath in split(globpath(&rtp,"syntax/python.vim"),"\n")
  if filereadable(fnameescape(s:pythonpath))
   let s:pythonpath= fnameescape(s:pythonpath)
   break
  endif
 endfor
endif
"if g:vimsyn_embed =~ 'P' && filereadable(s:pythonpath)
if filereadable(s:pythonpath)
 unlet! b:current_syntax
 exe "syn include @texPythonScript ".s:pythonpath
 "if exists("g:vimsyn_folding") && g:vimsyn_folding =~ 'P'
 if g:tex_fold_enabled && has("folding")
  " Match python << endpython
  syn region texPythonRegion fold matchgroup=texScriptDelim start=+py\%[thon]3\=\s*<<\s*\z(.*\)$+ end=+^[ ]*\z1$+	contains=@NoSpell,@texPythonScript
  syn region texPythonRegion fold matchgroup=texScriptDelim start=+py\%[thon]3\=\s*<<\s*$+ end=+\.$+		contains=@NoSpell,@texPythonScript
 else
  syn region texPythonRegion matchgroup=texScriptDelim start=+py\%[thon]3\=\s*<<\s*\z(.*\)$+ end=+^[ ]*\z1$+		contains=@NoSpell,@texPythonScript
  syn region texPythonRegion matchgroup=texScriptDelim start=+py\%[thon]3\=\s*<<\s*$+ end=+\.$+		contains=@NoSpell,@texPythonScript
 endif
 "syn cluster vimFuncBodyList	add=texPythonRegion
 "syn cluster texCommentGroup	add=texPythonRegion
else
 syn region texEmbedError start=+py\%[thon]3\=\s*<<\s*\z(.*\)$+ end=+^\z1$+ contains=@NoSpell
 syn region texEmbedError start=+py\%[thon]3\=\s*<<\s*$+ end=+\.$+ contains=@NoSpell
endif
unlet s:pythonpath
" L________________________________________

let s:extfname=expand("%:e")
if exists("g:tex_stylish")
 let b:tex_stylish= g:tex_stylish
elseif !exists("b:tex_stylish")
 if s:extfname == "sty" || s:extfname == "cls" || s:extfname == "clo" || s:extfname == "dtx" || s:extfname == "ltx"
  let b:tex_stylish= 1
 else
  let b:tex_stylish= 0
 endif
endif


" Adapted FROM verbatim zone in $VIMRUNTIME/syntax/tex.vim
"if s:tex_fast =~ 'v'
if exists("g:tex_verbspell") && g:tex_verbspell
    syn region texZone		start="\\begin{[cC]omment}"		end="\\end{[cC]omment}\|%stopzone\>"	contains=@NoSpell,texPythonRegion
    " listings package:
    syn region texZone		start="\\begin{lstlisting}"		end="\\end{lstlisting}\|%stopzone\>"	contains=@NoSpell,texPythonRegion
    syn region texZone		start="\\begin{minted}"		end="\\end{minted}\|%stopzone\>"	contains=@NoSpell,texPythonRegion
    syn region texZone		start="\\begin{pytheoncode.\?}"		end="\\end{pythoncode.\?}\|%stopzone\>"	contains=@NoSpell,texPythonRegion
    if version < 600
        syn region texZone		start="\\comment\*\=`"			end="`\|%stopzone\>"			contains=@NoSpell,texPythonRegion
        syn region texZone		start="\\comment\*\=#"			end="#\|%stopzone\>"			contains=@NoSpell,texPythonRegion
    else
        if b:tex_stylish
            syn region texZone		start="\\comment\*\=\z([^\ta-zA-Z@]\)"	end="\z1\|%stopzone\>"			contains=@NoSpell,texPythonRegion
        else
            syn region texZone		start="\\comment\*\=\z([^\ta-zA-Z]\)"	end="\z1\|%stopzone\>"			contains=@NoSpell,texPythonRegion
        endif
    endif
else
    syn region texZone		start="\\begin{[cC]omment}"		end="\\end{[cC]omment}\|%stopzone\>" contains=texPythonRegion
    syn region texZone		start="\\begin{minted}"		end="\\end{minted}\|%stopzone\>" contains=texPythonRegion
    syn region texZone		start="\\begin{pythoncode.\?}"		end="\\end{pythoncode.\?}\|%stopzone\>" contains=texPythonRegion
    if version < 600
        syn region texZone		start="\\comment\*\=`"			end="`\|%stopzone\>"  contains=texPythonRegion
        syn region texZone		start="\\comment\*\=#"			end="#\|%stopzone\>"  contains=texPythonRegion
    else
        if b:tex_stylish
            syn region texZone		start="\\comment\*\=\z([^\ta-zA-Z@]\)"	end="\z1\|%stopzone\>"  contains=texPythonRegion
        else
            syn region texZone		start="\\comment\*\=\z([^\ta-zA-Z]\)"	end="\z1\|%stopzone\>"  contains=texPythonRegion
        endif
    endif
endif
"endif
"

" Adapted FROM verbatim zone in $VIMRUNTIME/syntax/tex.vim
"if s:tex_fast =~ 'v'
  if exists("g:tex_verbspell") && g:tex_verbspell
   syn region texZone		start="\\begin{[cC]omment}"		end="\\end{[cC]omment}\|%stopzone\>"	contains=@NoSpell,texPythonRegion
   " listings package:
   syn region texZone		start="\\begin{lstlisting}"		end="\\end{lstlisting}\|%stopzone\>"	contains=@NoSpell,texPythonRegion
   if version < 600
    syn region texZone		start="\\comment\*\=`"			end="`\|%stopzone\>"			contains=@NoSpell,texPythonRegion
    syn region texZone		start="\\comment\*\=#"			end="#\|%stopzone\>"			contains=@NoSpell,texPythonRegion
   else
     if b:tex_stylish
      syn region texZone		start="\\comment\*\=\z([^\ta-zA-Z@]\)"	end="\z1\|%stopzone\>"			contains=@NoSpell,texPythonRegion
     else
      syn region texZone		start="\\comment\*\=\z([^\ta-zA-Z]\)"	end="\z1\|%stopzone\>"			contains=@NoSpell,texPythonRegion
     endif
   endif
  else
   syn region texZone		start="\\begin{[cC]omment}"		end="\\end{[cC]omment}\|%stopzone\>" contains=texPythonRegion
   if version < 600
    syn region texZone		start="\\comment\*\=`"			end="`\|%stopzone\>"  contains=texPythonRegion
    syn region texZone		start="\\comment\*\=#"			end="#\|%stopzone\>"  contains=texPythonRegion
   else
     if b:tex_stylish
       syn region texZone		start="\\comment\*\=\z([^\ta-zA-Z@]\)"	end="\z1\|%stopzone\>"  contains=texPythonRegion
     else
       syn region texZone		start="\\comment\*\=\z([^\ta-zA-Z]\)"	end="\z1\|%stopzone\>"  contains=texPythonRegion
     endif
   endif
  endif
"endif



syn region texRefZone		matchgroup=texStatement start="\\\(page\|eq\)cref{"	end="}\|%stopzone\>"	contains=@texRefGroup
syn region texRefZone		matchgroup=texStatement start="\\v\=cref{"		end="}\|%stopzone\>"	contains=@texRefGroup

syn region texRefZone		matchgroup=texStatement start="\\\(page\|eq\)ucref{"	end="}\|%stopzone\>"	contains=@texRefGroup
syn region texRefZone		matchgroup=texStatement start="\\v\=ucref{"		end="}\|%stopzone\>"	contains=@texRefGroup

syn region texRefZone		matchgroup=texStatement start="\\\(page\|eq\)dref{"	end="}\|%stopzone\>"	contains=@texRefGroup
syn region texRefZone		matchgroup=texStatement start="\\v\=dref{"		end="}\|%stopzone\>"	contains=@texRefGroup

syn region texRefZone		matchgroup=texStatement start="\\\(page\|eq\)Dref{"	end="}\|%stopzone\>"	contains=@texRefGroup
syn region texRefZone		matchgroup=texStatement start="\\v\=Dref{"		end="}\|%stopzone\>"	contains=@texRefGroup

syn region texRefZone		matchgroup=texStatement start="\\\(page\|eq\)Cref{"	end="}\|%stopzone\>"	contains=@texRefGroup
syn region texRefZone		matchgroup=texStatement start="\\v\=Cref{"		end="}\|%stopzone\>"	contains=@texRefGroup

syn region texRefZone		matchgroup=texStatement start="\\subimport{common}{"	end="}\|%stopzone\>"	contains=@texRefGroup
syn region texRefZone		matchgroup=texStatement start="\\v\=subimport{common}{"		end="}\|%stopzone\>"	contains=@texRefGroup

"HiLink texZone		PreCondit
syn match  texRefZone		'\\ucite\%([tp]\*\=\)\=' nextgroup=texRefOption,texCite


""""""
" Other stuff
"syn region SpecialKey		start="\\devcomment\*\=\z([^\ta-zA-Z@]\)"	end="\z1\|%stopzone\>"
"syn region SpecialKey	 start="\\chuckcomment{"	end="}\|%stopzone\>"	contains=@Spell
"
"


" SPELL CHECK INSIDE NEWCOMMAND
" References: http://stackoverflow.com/questions/13553342/vim-spell-checking-latexs-newcommand-definition

"syn region texMyCmdSpell matchgroup=texStatement
"      \ start='\\newcommand{.*{' end='}$'
"      \ contains=@Spell
"      \ containedin=texCmdBody

"syn region texMyCaptionSpell matchgroup=texStatement
"      \ start='\\caption{.*{' end='}$'
"      \ contains=@Spell
"      \ containedin=texCmdBody


" Custom command syntax highlight
syn match texInputFile		"\\ImageCommand{.\{-}}"	contains=texStatement,texInputCurlies,texInputFileOpt nextgroup=@Spell
syn match texInputFile		"\\ImageCommandII{.\{-}}"	contains=texStatement,texInputCurlies,texInputFileOpt nextgroup=@Spell

syn match texInputFile		"\\url{.\{-}}"	contains=texStatement,texInputCurlies,texInputFileOpt nextgroup=@Spell



" also from vim.vim
hi def link texScriptDelim	Comment
hi def link texEmbedError	texError
