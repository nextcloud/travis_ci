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
DB=$3
echo "Work directory: $WORKDIR"
echo "Database: $DB"

if [ "$DB" == "mysql" ] ; then
  if [ -z "$DATABASEHOST" ] || [ "$DATABASEHOST" = "localhost" ] ; then
    echo "Setting up mysql ..."
    mysql -e 'create database oc_autotest;'
    mysql -u root -e "CREATE USER 'oc_autotest'@'localhost' IDENTIFIED BY 'owncloud'";
    mysql -u root -e "grant all on oc_autotest.* to 'oc_autotest'@'localhost'";
    mysql -e "SELECT User FROM mysql.user;"
  else
    echo "Waiting for MySQL initialisation ..."
    if ! ../server/apps/files_external/tests/env/wait-for-connection $DATABASEHOST 3306 600; then
      echo "[ERROR] Waited 600 seconds, no response" >&2
      exit 1
    fi
  fi
fi

if [ "$DB" == "pgsql" ] ; then
  if [ -z "$DATABASEHOST" ] || [ "$DATABASEHOST" = "localhost" ] ; then
    createuser -U travis -s oc_autotest
  else
    echo "Waiting for Postgres to be available ..."
    if ! ../server/apps/files_external/tests/env/wait-for-connection $DATABASEHOST 5432 60; then
      echo "[ERROR] Waited 60 seconds for $DATABASEHOST, no response" >&2
      exit 1
    fi
    echo "Give it 10 additional seconds ..."
    sleep 10
  fi
fi

if [ "$DB" == "oracle" ] ; then
  DOCKER_CONTAINER_ID=$(docker run -d deepdiver/docker-oracle-xe-11g)
  export DATABASEHOST=$(docker inspect --format="{{.NetworkSettings.IPAddress}}" "$DOCKER_CONTAINER_ID")

  # TODO: wait for oracle
  if [ ! -f before_install_oracle.sh ]; then
    wget https://raw.githubusercontent.com/nextcloud/travis_ci/master/before_install_oracle.sh
  fi
  bash ./before_install_oracle.sh
fi

#
# copy custom php.ini settings
#
wget https://raw.githubusercontent.com/nextcloud/travis_ci/master/custom.ini
if [ $(phpenv version-name) != 'hhvm' ]; then
  phpenv config-add custom.ini
fi

#
# copy install script
#
cd ../server
if [ ! -f core_install.sh ]; then
    wget https://raw.githubusercontent.com/nextcloud/travis_ci/master/core_install.sh
fi

bash ./core_install.sh $DB

#
# install fixed phpunit version
#
cd ..

if [ "$CORE_BRANCH" == "stable13" -o "$CORE_BRANCH" == "stable12" -o "$CORE_BRANCH" == "stable11" -o "$CORE_BRANCH" == "stable10" -o "$CORE_BRANCH" == "stable9" ]; then
    wget https://raw.githubusercontent.com/nextcloud/travis_ci/master/composer-phpunit5.json
    mv composer-phpunit5.json composer.json
else
    wget https://raw.githubusercontent.com/nextcloud/travis_ci/master/composer.json
fi
composer install
export PATH="$PWD/vendor/bin:$PATH"
cd $WORKDIR
