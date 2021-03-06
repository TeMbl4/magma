#!/bin/bash

# Name: schema.init.sh
# Author: Ladar Levison
#
# Description: Used for quickly initializing the MySQL database used by the by the 
# magma daemon. This script should be only be run once in a production environment. 
# It may be used at the user's discretion against a sandbox environment.

LINK=`readlink -f $0`
BASE=`dirname $LINK`

cd $BASE/../../../

MAGMA_RES_SQL="res/sql/" 

case $# in
	0) 
    	echo "Using the default sandbox values for the MySQL username, password and schema name."
		MYSQL_USER="mytool"
		MYSQL_PASSWORD="aComplex1"
		MYSQL_SCHEMA="Lavabit"
	;;
	*!3*)
		echo "Ini "res/sql/" tialize the MySQL database used by the magma daemon."
		echo ""
		echo "Usage:    $0 \<mysql_user\> \<mysql_password\> \<mysql_schema\>"
		echo "Example:  $0 magma volcano Lavabit"
		echo ""
		exit 1
	;;
esac

if [ -z "$MYSQL_USER" ]; then
	if [ -z "$1" ]; then
		echo "Please pass in the MySQL username."
		exit 1
	else
		MYSQL_USER="$1"
	fi
fi

if [ -z "$MYSQL_PASSWORD" ]; then
	if [ -z "$2" ]; then
		echo "Please pass in the MySQL password."
		exit 1
	else
		MYSQL_PASSWORD="$2"
	fi
fi

if [ -z "$MYSQL_SCHEMA" ]; then
	if [ -z "$3" ]; then
		echo "Please pass in the MySQL schema name."
		exit 1
	else
		MYSQL_SCHEMA="$3"
	fi
fi

if [ ! -d $MAGMA_RES_SQL ]; then
	echo "The SQL scripts directory appears to be missing. { path = $MAGMA_RES_SQL }"
	exit 1
fi

# Generate Start.sql from the user-provided Schema
echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_SCHEMA}\`;
USE \`${MYSQL_SCHEMA}\`;

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;" > $MAGMA_RES_SQL/Start.sql

if [ -z "$HOSTNAME" ]; then
	HOSTNAME=$(hostname)
fi

# Generate Hostname.sql with the system's Hostname
echo "UPDATE Hosts SET hostname = '$HOSTNAME' WHERE hostnum = 1;" > $MAGMA_RES_SQL/Hostname.sql

cat $MAGMA_RES_SQL/Start.sql \
	$MAGMA_RES_SQL/Schema.sql \
	$MAGMA_RES_SQL/Data.sql \
	$MAGMA_RES_SQL/Migration.sql \
	$MAGMA_RES_SQL/Finish.sql \
	$MAGMA_RES_SQL/Hostname.sql \
	| mysql --batch -u ${MYSQL_USER} --password=${MYSQL_PASSWORD}


