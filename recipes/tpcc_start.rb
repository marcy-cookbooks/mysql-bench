#
# Cookbook Name:: .
# Recipe:: tpcc_start
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

execute 'tpcc-load' do
  cwd node['tpcc_dir']
  command <<-EOH
./tpcc_start \
-h #{node['mysql_host']} \
-d tpcc -u #{node['mysql_user']} \
-p #{node['mysql_pass']} \
-w #{node['tpcc_warehouse']} \
-c #{node['tpcc_connection']} \
-l #{node['tpcc_running_time']} \
-r #{node['tpcc_warmup_time']}
EOH
  only_if { File.exists?("#{node['tpcc_dir']}/tpcc_load") }
  action :nothing
end
