#!/bin/bash
## apt-get install cmake build-essential git libgl1-mesa-dev libxrandr-dev libfreetype6-dev libglew-dev libjpeg8-dev libopenal-dev libsndfile1-dev

## Optional 
## apt-get install gcc-mingw32

##Use Codeblocks? 1=yes 0=no  #apt-get install codeblocks
USECB=0
MAINDIR=~/code/emptyepsilon

echo Fetching...
if [ ! -d $MAINDIR/SeriousProton ]; then
	echo Cloning Repository for SeriousProton...
	git clone https://github.com/daid/SeriousProton.git
fi
if [ ! -d $MAINDIR/EmptyEpsilon ]; then
	echo Cloning Repository for EmptyEpsilon...
	git clone https://github.com/daid/EmptyEpsilon.git
fi

if [ ! -d $MAINDIR/SFML-2.1 ]; then
	echo Downloading SFML-2.1...
	wget https://github.com/LaurentGomila/SFML/archive/2.1.zip
	unzip 2.1.zip
	cd $MAINDIR/SFML-2.1
	echo Building and installing SFML-2.1
	## If cmake fails on FreeType, make sure that cmake is looking in /usr/include/freetype2 - this was not in the cmake on the RPi
	## to help fix use 
	# apt-get install cmake-curses-gui && ccmake .
	cmake . && make && sudo make install
fi

cd $MAINDIR/SeriousProton
BUILD=0

if [ "$1" == "-f" ]; then
 BUILD=1
fi

GITSTATUS=`git pull`

if [ "$GITSTATUS" == "Already up-to-date." ]; then 
	echo SeriousProton $GITSTATUS
else 
	echo $GITSTATUS
	BUILD=1
fi

cd $MAINDIR/EmptyEpsilon
GITSTATUS=`git pull`
if [ "$GITSTATUS" == "Already up-to-date." ]; then 
	echo EmptyEpsilon $GITSTATUS
else 
	echo $GITSTATUS
	BUILD=1
fi

if [ "$BUILD" == "0" ]  ; then
	echo Code is up to date, not building. Exiting.
	exit 2
else 
	echo New versions found, Building...

fi


GITVER=`git log --pretty=format:"%h" -1 `
echo GIT version: $GITVER

echo Cleaning old builds...
rm -rf  _build_*
rm $MAINDIR/EmptyEpsilon/.bin/Debug/EmptyEpsilon* $MAINDIR/EmptyEpsilon/.bin/Release/EmptyEpsilon*
rm $MAINDIR/EmptyEpsilon/EmptyEpsilon_debug* $MAINDIR/EmptyEpsilon/EmptyEpsilon_release*

echo Cleanup...
rm -rf $MAINDIR/EELin32
mkdir $MAINDIR/EELin32

echo Building...
if [ "$USECB" == "1" ]; then 
	echo Using Code::Blocks to Build...
	codeblocks EmptyEpsilon.cbp --no-splash-screen --rebuild EmptyEpsilon.cbp  --target="Linux Debug"
	cp $MAINDIR/EmptyEpsilon/.bin/Debug/EmptyEpsilon $MAINDIR/EELin32/EmptyEpsilon_debug.x86
	codeblocks EmptyEpsilon.cbp --no-splash-screen --rebuild EmptyEpsilon.cbp  --target="Linux Release"
	cp $MAINDIR/EmptyEpsilon/.bin/Release/EmptyEpsilon $MAINDIR/EELin32/EmptyEpsilon.x86
else
	echo Using Python to Build...
	##-- Binary Files created in EE parent directory
	python make_cbp.py debug
	if [ -e EmptyEpsilon ]; then
		mv EmptyEpsilon EmptyEpsilon_debug
	fi
	if [ -e EmptyEpsilon.exe ]; then
		mv EmptyEpsilon.exe EmptyEpsilon_debug.exe
	fi
	python make_cbp.py
	if [ -e EmptyEpsilon ]; then
		mv EmptyEpsilon EmptyEpsilon_release
	fi
	if [ -e EmptyEpsilon.exe ]; then
		mv EmptyEpsilon.exe EmptyEpsilon_release.exe
	fi
	cp $MAINDIR/EmptyEpsilon/EmptyEpsilon_* $MAINDIR/EELin32
fi

echo Copying Data files...
cp -r $MAINDIR/EmptyEpsilon/scripts $MAINDIR/EmptyEpsilon/resources $MAINDIR/EmptyEpsilon/packs $MAINDIR/EELin32
cp $MAINDIR/EmptyEpsilon/LICENSE $MAINDIR/EmptyEpsilon/README.md $MAINDIR/EELin32

cd $MAINDIR
echo Creating Archive...
NOW=`date +'%s'`
tar -zcvf EELin32_$NOW-$GITVER.tar.gz EELin32 
echo 
echo Done.
