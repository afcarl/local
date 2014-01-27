# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

# Unix aliases

alias ls='ls --color --human-readable --group-directories-first --hide="*.pyc"'
alias pygrep='grep -r --include "*.py"'
alias clean_python='rm -rf *.pyc'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias utarbz2='tar jxf'
#ipython --pdb -c "%run report_results2.py --BOW --no-print-checks"

#x - extract
#v - verbose output (lists all files as they are extracted)
#j - deal with bzipped file
#f - read from a file, rather than a tape device

clean_latex()
{
    rm *.aux
    rm *.bbl
    rm *.brf 
    rm *.log 
    rm *.bak 
    rm *.blg 
    rm *.tips 
    rm *.synctex
    rm main.pdf
    rm main.dvi
}
alias pyl='pylint --disable=C'
alias pyf='pyflakes'
alias lls='ls -I *.aux -I *.bbl -I *.blg -I *.out -I *.log -I *.synctex'
pdbpython()
{
    ipython --pdb -c "\"%run $@\""
}
#Find and replace in dir
search_replace_dir()
{
    echo find ./ -type f -exec sed -i "s/$1/$2/g" {} \;
}
# Download entire webpage
alias wget_all='wget --mirror --no-parent'
# Convert images
alias png2jpg='for f in *.png; do ffmpeg -i "$f" "${f%.png}.jpg"; done'


# Git
alias gcwip='git commit -am "wip"; git push'
alias gp='git pull'
hyrule_get(){
    git clone git@hyrule.cs.rpi.edu:$1
}

# General navigation
alias home='cd ~'
alias data='cd ~/data'
alias code='cd ~/code'
alias loc='cd ~/local'
alias lt='cd ~/latex'
alias scr='cd ~/scripts'
# Special navigation
alias hs='cd ~/code/hotspotter'
alias hes='cd ~/code/hesaff'
alias cand='cd ~/latex/crall-candidacy-2013/'

alias vdd='vd ~/data'
alias ..="cd .."
alias l='ls $LS_OPTIONS -lAhF'
alias gits='git status'


# ROB
alias hskill='rob hskill'
alias nr='rob grepnr'
alias rgrep='rob grepnr'
alias rsc='rob research_clipboard None 3'
#alias rob='python $PORT_CODE/Rob/for f in *.png; do ffmpeg -i "$f" "${f%.png}.jpg"; done'
alias rob='python ~/local/rob/run_rob.py'
alias rls='rob ls'
alias er='gvim $prob'
alias ebrc='gvim ~/local/bashrc.sh'
alias sbrc='source ~/local/bashrc.sh' # Refresh
alias todo='gvim ~/Dropbox/Notes/TODO.txt'
alias ic='python investigate_chip.py'
alias icG='python investigate_chip.py --db GZ'
alias icM='python investigate_chip.py --db MOTHERS'

# Reload profile
alias rrr='source ~/.profile'
update_profile()
{
    pushd .
    loc
    git pull
    rrr
    popd
}
commit_profile()
{
    pushd .
    loc
    git commit -am "profile wip"
    git push
    popd
}
alias upp=update_profile
alias cop=commit_profile
