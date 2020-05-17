#!/usr/bin/env bash

source ./data_service.sh

cleanup() {
    stop_data_service
    rm -rf /var/spool/chatapp
    exit 1
}

db_trust_login() {
    datastore_dir=/var/spool/chatapp/datastore
    if [ "xx${1}xx" == "xxSETxx" ] ; then
        err=$(sed -i 's/md5/trust/g' ${datastore_dir}/pg_hba.conf 2>&1)
        ret=$?
    else
        err=$(sed -i 's/trust/md5/g' ${datastore_dir}/pg_hba.conf 2>&1)
        ret=$?
    fi
    if [ $? -ne 0 ]; then
        echo "${err}"
        return 1
    fi
    return 0
}

initialize_db() {
    PGSQL_CMD=$(type psql 2>/dev/null | cut -d' ' -f3)
    if [ -z "$PGSQL_CMD" ]; then
        echo "psql command is not in PATH"
        cleanup
    fi
    PGSQL_CONF=$(type pg_config 2>/dev/null | cut -d' ' -f3)
    if [ -z "$PGSQL_CONF" ]; then
        PGSQL_BIN=$(dirname ${PGSQL_CMD})
    else
        PGSQL_BIN=$(${PGSQL_CONF} | awk '/BINDIR/{ print $3 }')
    fi
    INITDB="${PGSQL_BIN}/initdb"
    PG_CTL="${PGSQL_BIN}/pg_ctl"
    echo "Initializing postgres data cluster for Chat..."
    echo "**"
    echo "**"
    dbuser="postgres"
    dbport=9876
    pgpasswd="/var/spool/chatapp/pgpassword"
    pguser="/var/spool/chatapp/pguser"
    pgdata="/var/spool/chatapp/datastore"
    pgpass=$(cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c32)
    if [ -d ${pgdata} ] ; then
        echo "Already datastore directory is present. Deleting it"
        rm -rf /var/spool/chatapp
    fi
    # Create data directory
    if [ ! -d "${pgdata}" ]; then
        mkdir -p "${pgdata}"
        if [ $? -ne 0 ]; then
            echo "Error creating dir ${pgdata}"
            cleanup
        fi
    fi
    chown ${dbuser} ${pgdata}
    if [ $? -ne 0 ]; then
        echo "Chown of ${pgdata} to user ${dbuser} failed"
        cleanup
    fi
    chmod 700 ${pgdata}
    if [ $? -ne 0 ]; then
        echo "chmod of ${pgdata} failed"
        cleanup
    fi
    echo ${dbuser} > ${pguser}
    echo ${pgpass} > ${pgpasswd}
    su - ${dbuser} -c "/bin/sh -c '${INITDB} -A md5 -D ${pgdata} -E utf-8 -U ${dbuser} --pwfile=${pgpasswd}'"
    if [ $? -ne 0 ] ; then
        echo "Unable to initialize database."
        cleanup
    fi
    rm -rf "/var/spool/chatapp/pgpassword"
    if [ $? -ne 0 ] ; then
        echo "Unable to remove file from /var/spool/chatapp directory."
        cleanup
    fi
    chmod 0600 "/var/spool/chatapp/pguser"
    if [ $? -ne 0 ] ; then
        echo "Unable to change permissions of database username: /var/spool/chatapp. Unable to initialize database."
        cleanup
    fi
    echo "**"
    echo "**"
    echo "Database initialized successfully"
}

initialize_db

db_trust_login "SET"

start_data_service

echo "Creating Database"
su - postgres -c 'psql -p 9876 -h 127.0.0.1  -c "create database chatdb"'
if [ $? -ne 0 ] ; then
    echo "Unable to create Chat database."
    cleanup
fi

echo "Database created. Now running sql files"
su - postgres -c 'psql -p 9876 -h 127.0.0.1 -f /home/ravi/Desktop/Projects/chat/chatApplication/database.sql'
if [ $? -ne 0 ] ; then
    echo "Unable create schema."
    cleanup
fi

db_trust_login "REVOKE"

stop_data_service
