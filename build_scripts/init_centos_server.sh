# Setup code directory
cd ~
mkdir ~/code
mkdir ~/tmp
mkdir ~/srcdistro

export NCPUS=$(grep -c ^processor /proc/cpuinfo)

# Give me some familiar and useful bashrc commands
export WORKON_HOME=~/Envs
echo "alias gp='git pull'" >> ~/.bashrc
echo "alias rrr='source ~/.bashrc'" >> ~/.bashrc
echo "alias ipy='ipython'" >> ~/.bashrc
echo "alias home='cd ~'" >> ~/.bashrc
echo "alias data='cd ~/data'" >> ~/.bashrc
echo "alias code='cd ~/code'" >> ~/.bashrc
echo "alias ib='cd ~/code/ibeis/'" >> ~/.bashrc
echo "alias s='git status'" >> ~/.bashrc

echo "export WORKON_HOME=~/Envs" >> ~/.bashrc

cat >> ~/.bashrc << _EOF_
ensuredir(){
    # Hacky oneline python for ensure dir with a print statment
    python -c "import os;func=(lambda:('ENSUREDIR: \$1', str(os.makedirs('\$1')))[0]) if not os.path.exists('\$1') else (lambda:'');print(func())"
}
_EOF_


grab_snapshot()
{
    echo "GRAB SNAPSHOT: $@ "
    export URL=$1
    export SNAPSHOT=$2
    cd ~/tmp
    wget $URL/$SNAPSHOT.tar.gz
    gunzip $SNAPSHOT.tar.gz && tar -xvf $SNAPSHOT.tar
    mv $SNAPSHOT ~/srcdistro/$SNAPSHOT
    cd ~/srcdistro/$SNAPSHOT
}

rrr

# Prereqs for python 2.7
sudo yum install -y gcc
sudo yum install -y gcc-c++
sudo yum install -y gcc-gfortran
sudo yum install -y kernel-devel
sudo yum install -y make
sudo yum install -y automake
sudo yum install -y git
sudo yum install -y git-core
sudo yum install -y xz-libs
sudo yum install -y zlib-dev sqlite-devel bzip2-devel
sudo yum install -y openssl-devel
sudo yum install -y openssl
sudo yum install -y readline-devel
sudo yum install -y tk-devel
sudo yum install -y ncurses-devel ncurses
sudo yum groupinstall 'Development Tools' -y
sudo yum upgrade -y wget
sudo yum upgrade -y openssl
sudo yum upgrade -y openssl-devel

# We actually need to build cmake from source
#sudo yum install -y cmake
sudo yum remove -y cmake
#===================
# SOURCE BUILD: CMAKE
cd ~/tmp
export CMAKE_SNAPSHOT=cmake-3.0.0
export CMAKE_URL=http://www.cmake.org/files/v3.0
grab_snapshot $CMAKE_URL $CMAKE_SNAPSHOT
./bootstrap
gmake -j$NCPUS && sudo make install
#===================

# Other prereqs
sudo yum install -y ffmpeg-devel
sudo yum install -y libpng-devel
sudo yum install -y libjpeg-devel
sudo yum install -y libtiff-devel
sudo yum install -y jasper jasper-devel
sudo yum install -y openjpeg-devel
sudo yum install -y openjpeg
sudo yum install -y littlecms
sudo yum install -y littlecms-devel
sudo yum install -y libpng
sudo yum install -y libtiff
sudo yum install -y libjpeg
sudo yum install -y zlib-devel
sudo yum install -y freetype-devel
sudo yum install -y fftw3-devel
sudo yum install -y atlas-devel

#===================
# SOURCE BUILD: PYTHON
# Download python 2.7
mkdir ~/tmp
cd ~/tmp
wget https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz
gunzip Python-2.7.6.tgz && tar -xvf Python-2.7.6.tar
mv Python-2.7.6 ~/srcdistro
# Configure, make, and altinstall python 2.7
cd ~/srcdistro/Python-2.7.6
./configure --prefix=/usr/local --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
make -j$NCPUS
sudo make altinstall
# Make the libraries in /usr/local/lib discoverable
#cat /etc/ld.so.conf
sudo sh -c "echo '/usr/local/lib' >> /etc/ld.so.conf"
#cat /etc/ld.so.conf
# These modules are obsolete and it is ok that they are not found
#bsddb185 dl imageop sunaudiodev 
#===================

# Install Pip >= 1.5 for python2.7
cd ~/tmp
wget https://bootstrap.pypa.io/get-pip.py
sudo /usr/local/bin/python2.7 get-pip.py
sudo /usr/local/bin/pip install pip --upgrade

# symlink for pi
sudo ln -s /usr/local/bin/pip2.7 /usr/local/bin/pip27
sudo ln -s /usr/local/bin/pip2.7 /usr/bin/pip2.7
sudo ln -s /usr/local/bin/pip2.7 /usr/bin/pip27
# symlink for py27
sudo ln -s /usr/local/bin/python2.7 /usr/local/bin/python27
sudo ln -s /usr/local/bin/python2.7 /usr/local/bin/py27
# symlink for root
sudo ln -s /usr/local/bin/python2.7 /usr/bin/python2.7
sudo ln -s /usr/bin/python2.7 /usr/bin/python27
sudo ln -s /usr/bin/python2.7 /usr/bin/py27
# THIS MESSES UP CENTOS. sudo ln -s /usr/local/bin/python2.7 /usr/local/bin/python2
# THIS MESSES UP CENTOS. sudo ln -s /usr/bin/python2.7 /usr/bin/python2


#====================
# SOURCE BUILD: QT
#sudo yum install -y qt4
#sudo yum install -y qt4-devel
# FIXME: The rest of this logic is in that file you forgot to commit
export QT_URL=http://download.qt-project.org/official_releases/qt/4.8/4.8.6
export QT_SNAPSHOT=qt-everywhere-opensource-src-4.8.6
cd ~/tmp
wget $QT_URL/$QT_SNAPSHOT.tar.gz
gunzip $QT_SNAPSHOT.tar.gz && tar -xvf $QT_SNAPSHOT.tar
mv $QT_SNAPSHOT ~/srcdistro
cd ~/srcdistro/$QT_SNAPSHOT
#gmake confclean
./configure --prefix=/usr/local/qt -prefix-install -openssl -confirm-license -opensource -shared
gmake -j$NCPUS
sudo gmake install
# symlink qmake to bin
sudo ln -s /usr/local/qt/bin/qmake /usr/bin/qmake
sudo sh -c "echo '/usr/local/qt/lib' >> /etc/ld.so.conf"

#====================

# Dont use virtual environment when setting up these python packages
#====================
# SOURCE BUILD: SIP
export SIP_URL=http://sourceforge.net/projects/pyqt/files/sip/sip-4.16
export SIP_SNAPSHOT=sip-4.16
cd ~/tmp
wget $SIP_URL/$SIP_SNAPSHOT.tar.gz
grabzippedurl.py $SIP_URL/$SIP_SNAPSHOT.tar.gz
gunzip $SIP_SNAPSHOT.tar.gz && tar -xvf $SIP_SNAPSHOT.tar
mv $SIP_SNAPSHOT ~/srcdistro
cd ~/srcdistro/$SIP_SNAPSHOT
python2.7 configure.py
make -j$NCPUS && sudo make install
python -c "import sip; print('[test] Python can import sip')"
#====================

#====================
# SOURCE BUILD: PyQt4
cd ~/tmp
# Use snapshot instead
#export PYQT4_SNAPSHOT=PyQt-x11-gpl-4.11.tar.gz
export PYQT4_URL=http://www.riverbankcomputing.co.uk/static/Downloads/PyQt4
export PYQT4_SNAPSHOT=PyQt-x11-gpl-4.11.1-snapshot-e1e46b3cad30
wget $PYQT4_URL/$PYQT4_SNAPSHOT.tar.gz
gunzip $PYQT4_SNAPSHOT.tar.gz && tar -xvf $PYQT4_SNAPSHOT.tar
mv $PYQT4_SNAPSHOT ~/srcdistro
cd ~/srcdistro/$PYQT4_SNAPSHOT
python27 configure-ng.py --qmake=/usr/local/qt/bin/qmake --no-designer-plugin --confirm-license --target-py-version=2.7
make -j$NCPUS && sudo make install
python2.7 -c "import PyQt4; print('[test] SUCCESS import PyQt4: %r' % PyQt4)"
python2.7 -c "from PyQt4 import QtGui; print('[test] SUCCESS import QtGui: %r' % QtGui)"
python2.7 -c "from PyQt4 import QtCore; print('[test] SUCCESS import QtCore: %r' % QtCore)"
python2.7 -c "from PyQt4.QtCore import Qt; print('[test] SUCCESS import Qt: %r' % Qt)"
#====================

# Setup a virtual environment to download all the IBEIS packages
sudo pip2.7 install virtualenv
# Virtual Env wrapper
sudo pip2.7 install virtualenvwrapper
#virtualenv-2.7 $WORKON_HOME/ibeis27
#source $WORKON_HOME/ibeis27/bin/activate
#echo "source $WORKON_HOME/ibeis27/bin/activate" >> .bashrc
# Check to see that it worked
#python --version

sudo pip27 install setuptools
sudo pip27 install setuptools --upgrade
sudo pip27 install Pygments
sudo pip27 install requests
sudo pip27 install colorama
sudo pip27 install psutil
sudo pip27 install functools32
sudo pip27 install six
sudo pip27 install dateutils
sudo pip27 install pyreadline
sudo pip27 install pyparsing
sudo pip27 install Cython
sudo pip27 install Pillow
sudo pip27 install numpy
sudo pip27 install numpy --upgrade
sudo pip27 install scipy
sudo pip27 install ipython
sudo pip27 install tornado
sudo pip27 install matplotlib
sudo pip27 install scikit-learn


# Configuration of pyqt4 and sip
# MAYBE Dont use virtualenv?
#export PYENV_ROOT=$WORKON_HOME/ibeis27
#export PYENV_BIN=$PYENV_ROOT/bin
#export PYENV_SITE=$PYENV_ROOT/lib/python2.7/site-packages
#export PYENV_INCLUDE=$PYENV_ROOT/python2.7
#export PYENV_SIP=$PYENV_ROOT/share/sip
#export COMMON_QT_CFG="--bindir=$PYENV_BIN --destdir=$PYENV_SITE --sipdir=$PYENV_SIP"

# Setup work directory
sudo mkdir /data/ibeis
sudo mkdir /data/ibeis/work
sudo mkdir /data/ibeis/raw
sudo mkdir /data/ibeis/logs

# Make symlink to work directory
ln -s /data/ibeis/work ~/work
ln -s /data/ibeis ~/data

# Clone IBEIS
cd code
git clone https://github.com/Erotemic/utool.git
sudo python2.7 setup.py develop
cd utool

git clone https://github.com/Erotemic/ibeis.git

cd ~/code/ibeis
python2.7 super_setup.py --build --develop

python27 main.py --workdir ~/work
python27 main.py --logdir ~/data/logs

##

#git config --global user.name "jon crall"
#git config --global user.email "crallj@rpi.edu"
#git config --global user.email "erotemic@gmail.com"
