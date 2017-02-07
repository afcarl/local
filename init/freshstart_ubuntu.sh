entry_prereq_git_and_local()
{
    # This is usually done manually
    sudo apt-get install git -y
    cd ~

    # Fix ssh keys if you have them
    ls -al ~/.ssh
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/known_hosts
    chmod 600 ~/.ssh/config
    chmod 400 ~/.ssh/id_rsa*


    # If local does not exist
    if [ ! -f ~/local ]; then
        git clone https://github.com/Erotemic/local.git
        cd local/init 
    fi
}


freshstart_ubuntu_entry_point()
{
    source ~/local/init/freshstart_ubuntu.sh
    entry_prereq_git_and_local
    freshstart_ubuntu_entry_point
}


ensure_config_symlinks()
{
    # Remove dead symlinks
    cd

    symlinks -d .
    
    export HOMELINKS=$HOME/local/homelinks

    # Symlink all homelinks files 
    BASEDIR=""
    #================
    mkdir -pv $HOME/.$BASEDIR
    FNAMES=$(/bin/ls -Ap $HOMELINKS/$BASEDIR | grep -v /)
    echo $FNAMES
    for f in $FNAMES; do ln -vs $HOMELINKS/$BASEDIR$f $HOME/.$BASEDIR$f; done
    #================

    # Symlink nautlius scripts
    BASEDIR="gnome2/nautilus-scripts/"
    #================
    mkdir -pv $HOME/.$BASEDIR
    FNAMES=$(/bin/ls -Ap $HOMELINKS/$BASEDIR | grep -v /)
    echo $FNAMES
    for f in $FNAMES; do ln -vs $HOMELINKS/$BASEDIR$f $HOME/.$BASEDIR$f; done
    #================

    # Symlink config subdirs
    BASEDIR="config/"
    #================
    mkdir -pv $HOME/.$BASEDIR
    DNAMES=$(/bin/ls -A $HOMELINKS/$BASEDIR)
    echo $DNAMES
    for d in $DNAMES; do ln -vs $HOMELINKS/$BASEDIR$d $HOME/.$BASEDIR$d; done
    #================
}

freshtart_ubuntu_entry_point()
{ 
    mkdir -p ~/tmp
    mkdir -p ~/code
    cd ~
    if [ ! -f ~/local ]; then
        git clone https://github.com/Erotemic/local.git
    fi
    # TODO UTOOL
    mv ~/.bashrc ~/.bashrc.orig
    mv ~/.profile ~/.profile.orig

    sudo apt-get install symlinks -y

    source ~/local/init/freshstart_ubuntu.sh
    ensure_config_symlinks

    ln -s ~/local/scripts/ubuntu_scripts ~/scripts
    source ~/.bashrc

    git config --global user.name joncrall
    git config --global user.email crallj@rpi.edu
    git config --global push.default current

    #sudo apt-get install trash-cli

    # Vim
    #sudo apt-get install -y vim
    #sudo apt-get install -y vim-gtk
    #sudo apt-get install -y vim-gnome-py2
    #sudo update-alternatives --set vim /usr/bin/vim.gnome-py2
    #sudo update-alternatives --set gvim /usr/bin/gvim.gtk-py2
    sudo apt-get install -y exuberant-ctags 

    # Terminal settings
    sudo apt-get install terminator -y

    # Development Environment
    sudo apt-get install gcc g++  -y
    sudo apt-get install -y gfortran
    sudo apt-get install -y build-essential 
    sudo apt-get install -y python-dev
    sudo apt-get install -y python3-dev 

    sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 10

    # Python 
    #sudo apt-get install python-dev -y
    #sudo apt-get install -y python-tk
    #sudo apt-get install python-pip -y
    #sudo pip install pip --upgrade
    #sudo pip install virtualenv
    #sudo pip install virtualenv --upgrade

    # setup virtual env
    #setup_venv2
    setup_venv3
    source ~/venv3/bin/activate

    pip install setuptools --upgrade
    pip install six
    pip install jedi
    pip install ipython
    pip install pep8 autopep8 flake8 pylint line_profiler

    mkdir -p ~/local/vim/vimfiles/bundle

    source ~/local/vim/init_vim.sh
    ln -s ~/local/vim/vimfiles ~/.vim
    #mkdir ~/.vim_tmp
    echo "source ~/local/vim/portable_vimrc" > ~/.vimrc
    python ~/local/init/ensure_vim_plugins.py

    source ~/local/init/ubuntu_core_packages.sh

    # Install utool
    cd ~/code
    if [ ! -f ~/utool ]; then
        git clone git@github.com:Erotemic/utool.git
        cd utool
        pip install -e .
    fi

    # Get latex docs
    cd ~/latex
    if [ ! -f ~/latex ]; then
        mkdir -p ~/latex
        git clone git@hyrule.cs.rpi.edu.com:crall-candidacy-2015.git
    fi

    # Install machine specific things

    if [[ "$HOSTNAME" == "hyrule"  ]]; then 
        echo "SETUP HYRULE STUFF"
        customize_sudoers
        source settings_hyrule.sh
        hyrule_setup_sshd
        hyrule_setup_fstab
        hyrule_create_users
    elif [[ "$HOSTNAME" == "Ooo"  ]]; then 
        echo "SETUP Ooo STUFF"
        install_dropbox
        customize_sudoers
        nautilus_settings
        gnome_settings
        install_chrome
        # Make sure dropbox has been initialized first
        install_fonts

        # 
        install_spotify
    else
        echo "UNKNOWN HOSTNAME"
    fi

    # Extended development environment
    sudo apt-get install -y pkg-config
    sudo apt-get install -y libtk-img-dev
    sudo apt-get install -y libav-tools libgeos-dev 
    sudo apt-get install -y libfftw3-dev libfreetype6-dev 
    sudo apt-get install -y libatlas-base-dev liblcms1-dev zlib1g-dev
    sudo apt-get install -y libjpeg-dev libopenjpeg-dev libpng12-dev libtiff5-dev

    pip install numpy
    pip install scipy
    pip install Cython
    pip install pandas
    pip install statsmodels
    pip install scikit-learn

    pip install matplotlib

    pip install functools32
    pip install psutil
    pip install six
    pip install dateutils
    pip install pyreadline
    #pip install pyparsing
    pip install parse
    
    pip install networkx
    pip install Pygments
    pip install colorama

    pip install requests
    pip install simplejson
    pip install flask
    pip install flask-cors

    pip install lockfile
    pip install lru-dict
    pip install shapely

    # pydot is currently broken
    #http://stackoverflow.com/questions/15951748/pydot-and-graphviz-error-couldnt-import-dot-parser-loading-of-dot-files-will
    #pip uninstall pydot
    pip uninstall pyparsing
    pip install -Iv 'https://pypi.python.org/packages/source/p/pyparsing/pyparsing-1.5.7.tar.gz#md5=9be0fcdcc595199c646ab317c1d9a709'
    pip install pydot
    python -c "import pydot"

    # Ubuntu hack for pyqt4
    # http://stackoverflow.com/questions/15608236/eclipse-and-google-app-engine-importerror-no-module-named-sysconfigdata-nd-u
    #sudo apt-get install python-qt4-dev
    #sudo apt-get remove python-qt4-dev
    #sudo apt-get remove python-qt4
    #sudo ln -s /usr/lib/python2.7/plat-*/_sysconfigdata_nd.py /usr/lib/python2.7/
    #python -c "import PyQt4"
    # TODO: install from source this is weird it doesnt work
    # sudo apt-get autoremove
}



setup_venv2(){
    # ENSURE SYSTEM PIP IS SAME AS SYSTEM PYTHON
    # sudo update-alternatives --set pip /usr/local/bin/pip2.7
    # sudo rm /usr/local/bin/pip
    # sudo ln -s /usr/local/bin/pip2.7 /usr/local/bin/pip
    sudo apt-get install curl -y
    sudo curl https://bootstrap.pypa.io/get-pip.py | sudo python2
    sudo pip2 install pip setuptools virtualenv -U

    export PYTHON2_VENV="$HOME/venv2"
    mkdir $PYTHON2_VENV
    python2 -m virtualenv -p /usr/bin/python2.7 $PYTHON2_VENV 
    #python2 -m virtualenv --relocatable $PYTHON2_VENV 
}

setup_venv3(){
    # Ensure PIP, setuptools, and virtual are on the SYSTEM
    sudo apt-get install curl -y
    sudo curl https://bootstrap.pypa.io/get-pip.py | sudo python3
    sudo pip3 install pip setuptools virtualenv -U

    export PYTHON3_VENV="$HOME/venv3"
    mkdir -p $PYTHON3_VENV
    python3 -m virtualenv -p /usr/bin/python3 $PYTHON3_VENV
    python3 -m virtualenv --relocatable $PYTHON3_VENV 
    # source $PYTHON3_VENV/bin/activate

    # Now ensure the correct pip is installed locally
    #pip3 --version
    # should be for 3.x
}
setupt_venvpypy(){

    export PYPY_VENV="$HOME/venvpypy"
    mkdir -p $PYPY_VENV
    virtualenv-3.4 -p /usr/bin/pypy $PYPY_VENV 

    pypy -m ensurepip
    sudo apt-get install pypy-pip
}

install_chrome()
{
    # Google PPA
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo apt-get update
    # Google Chrome
    sudo apt-get install -y google-chrome-stable 
}


install_fonts()
{
    sudo apt-get -y install nautilus-dropbox
    sudo cp ~/Dropbox/Fonts/*.ttf /usr/share/fonts/truetype/
    sudo cp ~/Dropbox/Fonts/*.otf /usr/share/fonts/opentype/
    sudo fc-cache

    mkdir -p ~/tmp 
    cd ~/tmp
    wget https://github.com/antijingoist/open-dyslexic/archive/master.zip
    7z x master.zip
    sudo cp ~/tmp/open-dyslexic-master/otf/*.otf /usr/share/fonts/opentype/
    sudo fc-cache

    wget http://www.myfontfree.com/zip.php?itnetid=37252&submit=70lcpj0ftroiesv26mvtqkbph3
}

virtualbox_ubuntu_init()
{
    sudo apt-get install dkms 
    sudo apt-get update
    sudo apt-get upgrade
    # Press Ctrl+D to automatically install virtualbox addons do this
    sudo apt-get install virtualbox-guest-additions-iso
    sudo apt-get install dkms build-essential linux-headers-generic
    sudo apt-get install build-essential linux-headers-$(uname -r)
    sudo apt-get install virtualbox-ose-guest-x11
    # setup virtualbox for ssh
    VBoxManage modifyvm virtual-ubuntu --natpf1 "ssh,tcp,,3022,,22"
}

customize_sudoers()
{ 
    # References: http://askubuntu.com/questions/147241/execute-sudo-without-password
    # Make timeout for sudoers a bit longer
    sudo cat /etc/sudoers > ~/tmp/sudoers.next  
    sed -i 's/^Defaults.*env_reset/Defaults    env_reset, timestamp_timeout=480/' ~/tmp/sudoers.next 
    # Copy over the new sudoers file
    sudo visudo -c -f ~/tmp/sudoers.next
    if [ "$?" -eq "0" ]; then
        sudo cp ~/tmp/sudoers.next /etc/sudoers
    fi 
    rm ~/tmp/sudoers.next
    #cat ~/tmp/sudoers.next  
    #sudo cat /etc/sudoers 
} 


nopassword_on_sudo()
{ 
    # CAREFUL. THIS IS HUGE SECURITY RISK
    # References: http://askubuntu.com/questions/147241/execute-sudo-without-password
    sudo cat /etc/sudoers > ~/tmp/sudoers.next  
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> ~/tmp/sudoers.next  
    # Copy over the new sudoers file
    visudo -c -f ~/tmp/sudoers.next
    if [ "$?" -eq "0" ]; then
        sudo cp ~/tmp/sudoers.next /etc/sudoers
    fi 
    rm ~/tmp/sudoers.next
} 

 
gnome_settings()
{
    # NOTE: mouse scroll wheel behavior was fixed by unplugging and replugging
    # the mouse. Odd. 

    #gconftool-2 --all-dirs "/"
    #gconftool-2 --all-dirs "/desktop/url-handlers"
    #gconftool-2 -a "/desktop/url-handlers"
    #gconftool-2 -a "/desktop/applications"
    #gconftool-2 --all-dirs "/schemas/desktop"
    #gconftool-2 --all-dirs "/apps"
    #gconftool-2 -R /desktop
    #gconftool-2 -R /
    #gconftool-2 --get /apps/nautilus/preferences/desktop_font
    #gconftool-2 --get /desktop/gnome/interface/monospace_font_name

    #gconftool-2 -a "/apps/gnome-terminal/profiles/Default" 
    #gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
    #sudo -u gdm gconftool-2 --type=bool --set /desktop/gnome/sound/event_sounds false
    #sudo apt-get install -y gnome-tweak-tool

    gconftool-2 --set "/apps/gnome-terminal/profiles/Default/background_color" --type string "#1111111"
    gconftool-2 --set "/apps/gnome-terminal/profiles/Default/foreground_color" --type string "#FFFF6999BBBB"
    gconftool-2 --set /apps/gnome-screensaver/lock_enabled --type bool false
    gconftool-2 --set /desktop/gnome/sound/event_sounds --type=bool false

    # try and disable password after screensaver lock
    gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
    gsettings set org.gnome.desktop.screensaver lock-enabled false


    # Fix search in nautilus (remove recurison)
    # http://askubuntu.com/questions/275883/traditional-search-as-you-type-on-newer-nautilus-versions
    gsettings set org.gnome.nautilus.preferences enable-interactive-search true
    #gsettings set org.gnome.nautilus.preferences enable-interactive-search false

    gconftool-2 --get /apps/gnome-screensaver/lock_enabled 
    gconftool-2 --get /desktop/gnome/sound/event_sounds

    #sudo apt-get install nautilus-open-terminal
}


nautilus_settings()
{
    # Get rid of anyonying nautilus sidebar items
    echo "Get Rid of anoying sidebar items"
    chmod +w ~/.config/user-dirs.dirs
    sed -i 's/XDG_TEMPLATES_DIR/#XDG_TEMPLATES_DIR/' ~/.config/user-dirs.dirs 
    sed -i 's/XDG_PUBLICSHARE_DIR/#XDG_PUBLICSHARE_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_DOCUMENTS_DIR/#XDG_DOCUMENTS_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_MUSIC_DIR/#XDG_MUSIC_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_PICTURES_DIR/#XDG_PICTURES_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_VIDEOS_DIR/#XDG_VIDEOS_DIR/' ~/.config/user-dirs.dirs
    echo "enabled=true" >> ~/.config/user-dirs.conf
    chmod -w ~/.config/user-dirs.dirs
    #cat ~/.config/user-dirs.conf 
    #cat ~/.config/user-dirs.dirs 
    #cat ~/.config/user-dirs.locale
    #cat /etc/xdg/user-dirs.conf 
    #cat /etc/xdg/user-dirs.defaults 
    ###
    sudo sed -i 's/TEMPLATES/#TEMPLATES/'     /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/PUBLICSHARE/#PUBLICSHARE/' /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/DOCUMENTS/#DOCUMENTS/'     /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/MUSIC/#MUSIC/'             /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/PICTURES/#PICTURES/'       /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/VIDEOS/#VIDEOS/'           /etc/xdg/user-dirs.defaults 
    ###
    sudo sed -i "s/enabled=true/enabled=false/" /etc/xdg/user-dirs.conf
    sudo echo "enabled=false" >> /etc/xdg/user-dirs.conf
    sudo sed -i "s/enabled=true/enabled=false/" /etc/xdg/user-dirs.conf
    xdg-user-dirs-gtk-update

    #echo "Get Open In Terminal in context menu"
    #sudo apt-get install nautilus-open-terminal -y

    # Tree view for nautilus
    gsettings set org.gnome.nautilus.window-state side-pane-view "tree"


    #http://askubuntu.com/questions/411430/open-the-parent-folder-of-a-symbolic-link-via-right-click

    mkdir -p ~/.gnome2/nautilus-scripts
}

setup_ibeis()
{
    mkdir -p ~/code
    cd ~/code
    if [ ! -f ~/ibeis ]; then
        git clone https://github.com/Erotemic/ibeis.git
    fi
    cd ~/code/ibeis
    git pull
    git checkout next
    ./_scripts/bootstrap.py
    ./_scripts/__install_prereqs__.sh
    ./super_setup.py --build --develop
    ./super_setup.py --checkout next
    ./super_setup.py --build --develop

    # Options
    ./_scripts/bootstrap.py --no-syspkg --nosudo

    cd 
    export IBEIS_WORK_DIR="$(python -c 'import ibeis; print(ibeis.get_workdir())')"
    echo $IBEIS_WORK_DIR
    ln -s $IBEIS_WORK_DIR  work
}
