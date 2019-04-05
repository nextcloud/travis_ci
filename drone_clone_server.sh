#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2014 Thomas Müller thomas.mueller@tmit.eu
#

set -e

WORKDIR=$PWD
APP_NAME=$1
CORE_BRANCH=$2
echo "Work directory: $WORKDIR"
cd ..
git clone --depth 1 -b $CORE_BRANCH https://github.com/nextcloud/server
cd server
git submodule update --init

cd apps
cp -R $WORKDIR/ $APP_NAME
cd $WORKDIR
echo $PWD
