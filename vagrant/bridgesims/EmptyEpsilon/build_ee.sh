#!/bin/bash
#We are not going to assume we are in the /home/vagrant directory
BUILDHOME=`pwd`

# update system
apt-get update
#apt-get -y upgrade
# install tools
apt-get -y install libexpat-dev libcurl4-openssl-dev  libarchive-dev libbz2-dev libLZMA-dev build-essential git libgl1-mesa-dev libxrandr-dev libfreetype6-dev libglew-dev libjpeg-dev libopenal-dev libxcb1-dev libxcb-image0-dev libudev-dev libflac-dev libvorbis-dev  unzip zip mingw32
# Clone repos
git clone https://github.com/daid/SeriousProton.git
git clone https://github.com/daid/EmptyEpsilon.git
# Get SFML 2.3.2
git clone https://github.com/SFML/SFML.git -b 2.3.x SFML-2.3
# Get DRMingW for Debugging Windows Build
git clone https://github.com/jrfonseca/drmingw.git
#grab cmake
wget http://www.cmake.org/files/v3.5/cmake-3.5.1.tar.gz

echo Build cmake
tar -xf cmake-3.5.1.tar.gz -C $BUILDHOME
cd $BUILDHOME/cmake-3.5.1
./bootstrap --prefix=/usr       \
            --system-libs       \
            --mandir=/share/man \
            --no-system-jsoncpp \
            --docdir=/share/doc/cmake-3.5.1 &&
make
sudo make install

echo Build SFML for Linux
cd $BUILDHOME/SFML-2.3
if [ ! -d lin32 ]; then
 mkdir lin32
fi
cd lin32
cmake ..  && make  && sudo make install 

echo Build SFML for Windows
cd $BUILDHOME/SFML-2.3
if [ ! -d win32 ]; then
 mkdir win32
fi
cd win32
# We're using the CMake Tool chain file from EE here to make it easier to compile for Windows
cmake -DCMAKE_TOOLCHAIN_FILE=$BUILDHOME/EmptyEpsilon/cmake/mingw.toolchain -DOPENAL_LIBRARY=$BUILDHOME/SFML-2.3/extlibs/bin/x86/openal32.dll ..
make

echo Build DrMingW for Windows
cd $BUILDHOME/drmingw
if [ ! -d win32 ]; then
 mkdir win32
fi
cd win32
    # We're using the CMake Tool chain file from EE here to make it easier to compile for Windows
cmake -DCMAKE_TOOLCHAIN_FILE=$BUILDHOME/EmptyEpsilon/cmake/mingw.toolchain ..
sudo make install

#Work around for "-lexchndl" missing dll
sudo cp bin/exchndl.dll /usr/lib/gcc/i686-w64-mingw32/4.9-win32/

sudo ldconfig


echo Build EmptyEpsilon for Linux
cd $BUILDHOME/EmptyEpsilon
#Write short commit name to file for later user
git log --pretty=format:'%h' -n 1 > ../eecommitver.log

if [ ! -d lin32 ]; then
 mkdir lin32
fi
cd lin32
cmake -DSERIOUS_PROTON_DIR=$BUILDHOME/SeriousProton/ -DSFML_ROOT=$BUILDHOME/SFML-2.3 ..
make

echo Build EmptyEpsilon for Windows
cd $BUILDHOME/EmptyEpsilon
if [ ! -d win32 ]; then
 mkdir win32
fi
cd win32
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS:STRING=-DSFML_STATIC -DCMAKE_TOOLCHAIN_FILE=$BUILDHOME/EmptyEpsilon/cmake/mingw.toolchain -DSERIOUS_PROTON_DIR=$BUILDHOME/SeriousProton/ -DSFML_ROOT=$BUILDHOME/SFML-2.3/win32 -DMING_DLL_PATH=/usr/lib/gcc/i686-w64-mingw32/4.9-win32 -DENABLE_CRASH_LOGGER=1 ..
make

echo Setup for Zip File
cd $BUILDHOME/EmptyEpsilon
python compile_script_docs.py > scripts_docs.html
cd $BUILDHOME
if [ ! -d $BUILDHOME/EE_ZIP ]; then
  mkdir $BUILDHOME/EE_ZIP
fi 

if [ -d $BUILDHOME/EE_ZIP/EmptyEpsilon ]; then
  sudo rm -rf $BUILDHOME/EE_ZIP/EmptyEpsilon/*
else
  mkdir $BUILDHOME/EE_ZIP/EmptyEpsilon
fi 

echo Copying Folders...
cp -rv $BUILDHOME/EmptyEpsilon/packs $BUILDHOME/EmptyEpsilon/scripts $BUILDHOME/EmptyEpsilon/resources $BUILDHOME/EE_ZIP/EmptyEpsilon
echo
echo Copying Binaries...
cp -v $BUILDHOME/EmptyEpsilon/win32/EmptyEpsilon.exe $BUILDHOME/EmptyEpsilon/lin32/EmptyEpsilon $BUILDHOME/EE_ZIP/EmptyEpsilon
echo
echo Copying Support Files...
cp -v $BUILDHOME/EmptyEpsilon/artemis_mission_convert* $BUILDHOME/EmptyEpsilon/LICENSE $BUILDHOME/EmptyEpsilon/logo.svg $BUILDHOME/EmptyEpsilon/README.md $BUILDHOME/EmptyEpsilon/scripts_docs.html  $BUILDHOME/EE_ZIP/EmptyEpsilon
echo
echo Copying DLL files...
cp -v $BUILDHOME/SFML-2.3/win32/lib/*.dll $BUILDHOME/SFML-2.3/extlibs/bin/x86/openal32.dll $BUILDHOME/drmingw/win32/bin/*.dll /usr/lib/gcc/i686-w64-mingw32/4.9-win32/libstdc++-6.dll /usr/lib/gcc/i686-w64-mingw32/4.9-win32/libgcc_s_sjlj-1.dll /usr/i686-w64-mingw32/lib/libwinpthread-1.dll/*.dll  $BUILDHOME/EE_ZIP/EmptyEpsilon
echo
echo Copying Reference files...
cp -v $BUILDHOME/eecommitver.log $BUILDHOME/EE_ZIP/EmptyEpsilon
echo
cd $BUILDHOME/EE_ZIP
zip -r EmptyEpsilon_$(date +"%Y%m%d")_$(cat $BUILDHOME/eecommitver.log).zip $BUILDHOME/EE_ZIP/EmptyEpsilon


if [ -d /vagrant ]; then
 #From Here we are assuming you're using vagrant, since there is a /vagrant directory
 cp EmptyEpsilon_$(date +"%Y%m%d")_$(cat $BUILDHOME/eecommitver.log).zip /vagrant
 cd $BUILDHOME

 echo Changing owner to vagrant of all files in the home directory incase we need to interactively work with these files 
 sudo chown -R vagrant:vagrant $BUILDHOME
fi
