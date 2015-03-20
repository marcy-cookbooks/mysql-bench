#
# Cookbook Name:: .
# Recipe:: tpcc_install
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'build-essential'

package 'bzr'
package 'mysql'
package 'mysql-devel'

execute 'bzr-checkout' do
  cwd File.dirname(node['tpcc_dir'])
  command "bzr branch lp:~percona-dev/perconatools/tpcc-mysql"
  not_if { Dir.exists?(node['tpcc_dir']) }
end

execute 'make-tpcc' do
  cwd "#{node['tpcc_dir']}/src"
  command "make"
  not_if { File.exists?("#{node['tpcc_dir']}/tpcc_start") }
end
