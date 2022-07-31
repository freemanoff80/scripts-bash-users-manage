#!/bin/bash

HOSTS_LIST_TEST='./server-list-test'
HOSTS_LIST_CHECKED='./server-list-checked'

PORTS_ARRAY=(
22
30012
)

HOSTS_ARRAY_TEST=($(cat $HOSTS_LIST_TEST |grep -v -e "^#" ))

# Create File List Of Checked Hosts
if [ -f ]; then
    touch $HOSTS_LIST_CHECKED
fi


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

