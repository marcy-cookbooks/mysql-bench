#
# Cookbook Name:: .
# Recipe:: initialize
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

file "#{node['tpcc_dir']}/load.sh" do
  mode "755"
  action :create
  notifies :run, 'execute[tpcc-load]', :immediately
  content <<-EOH
#!/bin/bash

MYSQL=/usr/bin/mysql
TPCCLOAD=./tpcc_load
TABLESQL=./create_table.sql
CONSTRAINTSQL=./add_fkey_idx.sql
DEGREE=#{node['cpu']['total']}

SERVER=#{node['mysql_host']}
DATABASE=tpcc
USER=#{node['mysql_user']}
PASS=#{node['mysql_pass']}
WAREHOUSE=#{node['tpcc_warehouse']}

set -e
$MYSQL -h $SERVER -u $USER -p$PASS -e "DROP DATABASE IF EXISTS $DATABASE"
$MYSQL -h $SERVER -u $USER -p$PASS -e "CREATE DATABASE $DATABASE"
$MYSQL -h $SERVER -u $USER -p$PASS $DATABASE < $TABLESQL
$MYSQL -h $SERVER -u $USER -p$PASS $DATABASE < $CONSTRAINTSQL

echo 'Loading item ...'
$TPCCLOAD $SERVER $DATABASE $USER $PASS $WAREHOUSE 1 1 $WAREHOUSE > /dev/null

set +e
STATUS=0
trap 'STATUS=1; kill 0' INT TERM

for ((WID = 1; WID <= WAREHOUSE; WID++)); do
    echo "Loading warehouse id $WID ..."

    (
        set -e

        # warehouse, stock, district
        $TPCCLOAD $SERVER $DATABASE $USER $PASS $WAREHOUSE 2 $WID $WID > /dev/null

        # customer, history
        $TPCCLOAD $SERVER $DATABASE $USER $PASS $WAREHOUSE 3 $WID $WID > /dev/null

        # orders, new_orders, order_line
        $TPCCLOAD $SERVER $DATABASE $USER $PASS $WAREHOUSE 4 $WID $WID > /dev/null
    ) &

    PIDLIST=(${PIDLIST[@]} $!)

    if [ $((WID % DEGREE)) -eq 0 ]; then
        for PID in ${PIDLIST[@]}; do
            wait $PID

            if [ $? -ne 0 ]; then
                STATUS=1
            fi
        done

        if [ $STATUS -ne 0 ]; then
            exit $STATUS
        fi

        PIDLIST=()
    fi
done

for PID in ${PIDLIST[@]}; do
    wait $PID

    if [ $? -ne 0 ]; then
        STATUS=1
    fi
done

if [ $STATUS -eq 0 ]; then
    echo 'Completed.'
fi

exit $STATUS
EOH
end

execute 'tpcc-load' do
  cwd node['tpcc_dir']
  command "./load.sh"
  action :nothing
end
