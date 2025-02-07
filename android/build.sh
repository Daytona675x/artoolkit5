#!/bin/bash

#--------------------------------------------------------------------------
#
#  ARToolKit5
#  ARToolKit for Android
#
#  This file is part of ARToolKit.
#
#  ARToolKit is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  ARToolKit is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with ARToolKit.  If not, see <http://www.gnu.org/licenses/>.
#
#  As a special exception, the copyright holders of this library give you
#  permission to link this library with independent modules to produce an
#  executable, regardless of the license terms of these independent modules, and to
#  copy and distribute the resulting executable under terms of your choice,
#  provided that you also meet, for each linked independent module, the terms and
#  conditions of the license of that module. An independent module is a module
#  which is neither derived from nor based on this library. If you modify this
#  library, you may extend this exception to your version of the library, but you
#  are not obligated to do so. If you do not wish to do so, delete this exception
#  statement from your version.
#
#  Copyright 2015 Daqri, LLC.
#  Copyright 2011-2015 ARToolworks, Inc.
#
#  Authors: Julian Looser, Philip Lamb, with updates from John Wolf
#
#--------------------------------------------------------------------------
# Use this script to build the native libraries in ARToolKit for Android if you have
# changed any of the library source.
# The core libraries are built first, followed by the wrapper.
#--------------------------------------------------------------------------

#
# Find out where we are and change to our directory
#
OURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${OURDIR}"
echo "Working from directory \"$PWD\"."

# Set OS-dependent variables.
OS=`uname -s`
ARCH=`uname -m`
CPUS=
NDK_BUILD_SCRIPT_FILE_EXT=
if [[ "$OS" = "Linux" ]]; then
    echo Building on Linux \(${ARCH}\)
    CPUS=`/usr/bin/nproc`
elif [[ "$OS" = "Darwin" ]]; then
    echo Building on Apple Mac OS X \(${ARCH}\)
    CPUS=`/usr/sbin/sysctl -n hw.ncpu`
else #Checking for Windows in a non-cygwin dependent way.
    WinsOS=
    if [[ $OS ]]; then
        WinsVerNum=${OS##*-}
        if [[ $WinsVerNum = "10.0" || $WinsVerNum = "6.3" || $WinsVerNum = "6.1" ]]; then
						if [[ $WinsVerNum = "10.0" ]]; then
							WinsOS="Wins10"
						elif [[ $WinsVerNum = "6.3" ]]; then
							WinsOS="Wins8.1"
						else
							WinsOS="Wins7"
						fi
            echo Building on Microsoft ${WinsOS} Desktop \(${ARCH}\)
            export HOST_OS="windows"
            NDK_BUILD_SCRIPT_FILE_EXT=".cmd"
            CPUS=`/usr/bin/nproc`
        fi
    fi
fi

if [[ ! $CPUS ]]; then
    echo **Development platform not supported, exiting script**
    exit 1
fi

#
# Update <AR/config.h> if required.
#
if [[ "$1" == "clean" ]]; then
    rm -f ../include/AR/config.h
else
    if [[ ../include/AR/config.h.in -nt ../include/AR/config.h ]]; then
        cp -v ../include/AR/config.h.in ../include/AR/config.h;
    fi
fi

#
# Build the ARToolKit libraries.
#
$NDK/ndk-build$NDK_BUILD_SCRIPT_FILE_EXT -j $CPUS $1
NDK_BLD_RESULT=$?
if [[ ${NDK_BLD_RESULT} != "0" ]]; then
  echo Exiting ndk-build script abnormally terminated.
  exit ${NDK_BLD_RESULT}
fi

#
# Build ARWrapper
#
$NDK/ndk-build$NDK_BUILD_SCRIPT_FILE_EXT -j $CPUS NDK_APPLICATION_MK=jni/Application-ARWrapper.mk $1
NDK_BLD_RESULT=$?
if [[ ${NDK_BLD_RESULT} != "0" ]]; then
  echo Exiting ndk-build script abnormally terminated.
  exit ${NDK_BLD_RESULT}
fi

#
# Copy ARWrapper and dependencies to ./libs folder of ARBaseLib-based examples.
#
ARTK_LibsDir=libs

if [[ $1 != "clean" ]] ; then
    JDK_PROJS=" \
        ARSimple \
        ARSimpleInteraction \
        ARMarkerDistance \
        ARSimpleOpenGLES20 \
        ARDistanceOpenGLES20 \
        ARMulti \
    "
    for i in $JDK_PROJS
    do
        FirstChar=${i:0:1}
        LCFirstChar=`echo $FirstChar | tr '[:upper:]' '[:lower:]'`
        ModName=$LCFirstChar${i:1}
        cp -Rpvf ${ARTK_LibsDir} ../AndroidStudioProjects/${i}Proj/$ModName/src/main/
    done
fi
