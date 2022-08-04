#!/bin/bash

COMMAND_NAME=$1

WORK_USER=admin

HOSTS_LIST_TEST='./server-list-test'
HOSTS_LIST_CHECKED='./server-list-checked'
HOSTS_LIST_CLEAN='./server-list-clean'

#SSH_KEY_PRIVAT='~/.ssh/id_rsa_01'
#SSH_KEY_PUBLIC='~/.ssh/id_rsa_01.pub'
SSH_KEY_PRIVAT='/home/ldap/ssadmin/.ssh/id_rsa_01'
SSH_KEY_PUBLIC='/home/ldap/ssadmin/.ssh/id_rsa_01.pub'


PORTS_ARRAY=(
22
30012
)

# Check File HOSTS_LIST_TEST For Exist
if [ ! -f $HOSTS_LIST_TEST ]; then
    echo "!!! File $HOSTS_LIST_TEST Not Exist. Exit Programm.";
    exit 0;
fi

# Create File List Of Checked Hosts If Not Exist
if [ ! -f $HOSTS_LIST_CHECKED ]; then
    touch $HOSTS_LIST_CHECKED
fi

HOSTS_ARRAY_TEST=($(cat $HOSTS_LIST_TEST |grep -v -e "^#" ))


# Launch Options

case "$COMMAND_NAME" in


    scan_port)
    # Scan Port To Connect SSH (NetCat)

    echo "Scan Port To Connect SSH"

    for HOST in ${HOSTS_ARRAY_TEST[*]};
        do
            echo $HOST;
            COUNT=${#PORTS_ARRAY[*]};
    
            for PORT in ${PORTS_ARRAY[*]};
                do
                    (( COUNT-- ));
    
                    if [ $( nc -vz -w 3 $HOST $PORT &>/dev/null;echo $? ) -eq 0 ]; then
                        
                        echo "+++ Port $PORT Connected";
                        if [ -z $(cat $HOSTS_LIST_CHECKED |grep "$HOST:$PORT") ]; then
                            echo "$HOST:$PORT" >> $HOSTS_LIST_CHECKED;
                        fi
                        break;
    
                    else
                        
                        if [ $COUNT -lt 1 ]; then
                            
                            echo "--- Connect_Error";
                            if [ -z $(cat $HOSTS_LIST_CHECKED |grep "$HOST:connect_error") ]; then
                                echo "#$HOST:connect_error" >> $HOSTS_LIST_CHECKED;
                            fi
                        
                        fi
                    
                    fi
                done
        done
    ;;

    add_key)
    # Add SSH Key To Host

    echo "Add SSH Key To Host"

    HOSTS_PORT_CHECKED_ARRAY=($(cat $HOSTS_LIST_CHECKED| grep -v -e "^#" ))
    #echo "${#HOSTS_PORT_CHECKED_ARRAY[*]}";

    if [ ${#HOSTS_PORT_CHECKED_ARRAY[*]} -eq 0 ]; then
        echo "!!! List Is Empty";
    fi

    for HOST_PORT in ${HOSTS_PORT_CHECKED_ARRAY[*]};
        do
            HOST=$(echo $HOST_PORT|cut -d ":" -f 1 );
            PORT=$(echo $HOST_PORT|cut -d ":" -f 2 );

            ssh-copy-id -i $SSH_KEY_PUBLIC $WORK_USER@$HOST -p $PORT

        done

    ;;

    login_check)
    # Check SSH Login

    echo "Check SSH Login"

    HOSTS_PORT_CHECKED_ARRAY=($(cat $HOSTS_LIST_CHECKED| grep -v -e "^#" ))

    if [ ${#HOSTS_PORT_CHECKED_ARRAY[*]} -eq 0 ]; then
        echo "!!! List Is Empty";
    fi
    
    echo '';
    for HOST_PORT in ${HOSTS_PORT_CHECKED_ARRAY[*]};
        do
            HOST=$(echo $HOST_PORT|cut -d ":" -f 1 );
            PORT=$(echo $HOST_PORT|cut -d ":" -f 2 );
            
            ssh -i $SSH_KEY_PRIVAT $WORK_USER@$HOST -p $PORT "hostname; uname -s;";

        done

    ;;


    clear_list)
    # Create Clear Hosts List SSH Login

    echo "Create Clear Hosts List SSH Login"

    HOSTS_PORT_CHECKED_ARRAY=($(cat $HOSTS_LIST_CHECKED| grep -v -e "^#" ))

    if [ ${#HOSTS_PORT_CHECKED_ARRAY[*]} -eq 0 ]; then
        echo "!!! List Is Empty";
    fi
    
    # Create File List Of Checked Hosts If Not Exist
    if [ ! -f $HOSTS_LIST_CLEAN ]; then
        touch $HOSTS_LIST_CLEAN
    fi

    echo '';
    for HOST_PORT in ${HOSTS_PORT_CHECKED_ARRAY[*]};
        do
            HOST=$(echo $HOST_PORT|cut -d ":" -f 1 );
            PORT=$(echo $HOST_PORT|cut -d ":" -f 2 );
            
            #ssh -i $SSH_KEY_PRIVAT $WORK_USER@$HOST -p $PORT "hostname; uname -s;";
            #if [ $( ssh -i ~/.ssh/id_rsa_01 admin@ce07-01-tst 'echo OK' &>/dev/null;echo $? ) -eq 0 ]; then echo TRUE;fi
            echo -e " \n$HOST";
            if [ $( ssh -i $SSH_KEY_PRIVAT $WORK_USER@$HOST -p $PORT 'echo OK' &>/dev/null;echo $? ) -eq 0 ]; then 
                echo "+++ OK"
                if [ -z $(cat $HOSTS_LIST_CLEAN| grep "$HOST:$PORT") ]; then
                    echo "$HOST:$PORT" >> $HOSTS_LIST_CLEAN;
                fi
            else
                 echo "--- FAIL"
                if [ -z $(cat $HOSTS_LIST_CLEAN| grep "#$HOST:$PORT") ]; then
                    echo "#$HOST:$PORT" >> $HOSTS_LIST_CLEAN;
                fi

            fi

        done


    ;;
    


    *)
    # Print ERROR message if input don't exist

    #echo "Usage: sh users_del.sh {check_conn|check_os|check_users|delete_users}"
    echo "Usage: sh users_del.sh {scan_port|add_key|login_check|clear_list}"
    exit 1
    ;;

esac
exit 0
