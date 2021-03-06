#!/bin/bash -e
# Copyright 2016 C.S.I.R. Meraka Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# JasPer has no dependencies
# Project URL : http://www.ece.uvic.ca/~frodo/jasper/
. /etc/profile.d/modules.sh
SOURCE_FILE=$NAME-$VERSION.tar.gz
# We provide the base module which all jobs need to get their environment on the build slaves
module add ci
module add cmake
module add jpeg

mkdir -p ${WORKSPACE}
mkdir -p ${SRC_DIR}
mkdir -p ${SOFT_DIR}

#  Download the source file if it's not available locally.
#  we were originally using ncurses as the test application
if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
  mkdir -p $SRC_DIR
# use local mirrors if you can. Remember - UFS has to pay for the bandwidth!
  wget https://github.com/mdadams/jasper/archive/version-${VERSION}.tar.gz -O ${SRC_DIR}/${SOURCE_FILE}
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${SOURCE_FILE}
fi

file ${SRC_DIR}/${SOURCE_FILE}
# now unpack it into the workspace
tar xfz ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE}

# We will be running configure and make in this directory
cd ${WORKSPACE}/${NAME}-version-${VERSION}
mkdir -p build-${BUILD_NUMBER}
cd build-${BUILD_NUMBER}
cmake -G "Unix Makefiles" \
-H${WORKSPACE}/${NAME}-version-${VERSION} \
-B${PWD} \
-DCMAKE_INSTALL_PREFIX=${SOFT_DIR} \
-DJAS_ENABLE_LIBJPEG=true \
-DJAS_ENABLE_SHARED=true \
-DJAS_ENABLE_OPENGL=false \
-DJPEG_LIBRARY=$JPEG_DIR/lib/libjpeg.so \
-DJPEG_INCLUDE_DIR=${JPEG_DIR}/include
make
