cleanup() {
    stop_data_service
    rm -rf /var/spool/chatapp
    exit 1
}

start_data_service() {
    echo "Starting Chat dataservice..."
    pgdata="/var/spool/chatapp/datastore"
    cd ${pgdata}
    if [ $? -ne 0 ] ; then
        echo "Unable to change directory to ${pgdata}"
        cleanup
    fi
    pgstartfile="${pgdata}/pgstartfile"
    dbuser="postgres"
    dbport=9876
    su - ${dbuser} -c "/bin/sh -c '${PG_CTL} start -w -D ${pgdata} -l ${pgstartfile} -o \"-p ${dbport} -k ${pgdata}\"'"
    if [ $? -ne 0 ] ; then
        echo "Unable to start chat dataservice."
        cleanup
    fi
    echo "Chatapp dataservice started successfully."
    cd ${CWD}
}

stop_data_service() {
    echo "Stopping chat dataservice..."
    pgdata="/var/spool/chatapp/datastore"
    cd ${pgdata}
    if [ $? -ne 0 ] ; then
        echo "Could not change directory to ${pgdata}"
        cleanup
    fi
    dbuser="postgres"
    dbport=9876
    res=$(su - ${dbuser} -c "/bin/sh -c '${PG_CTL} -D ${pgdata} -o \"-p ${dbport}\" -w stop'")
    if [ $? -ne 0 ] ; then
        echo "Failed to stop chat data service"
        cleanup
    fi
    echo "Chatapp data service stopped"
    cd ${CWD}
}

if [ "$1" == "start" ] ; then
    start_data_service
elif [ "$1" == "stop" ] ; then
    stop_data_service
fi