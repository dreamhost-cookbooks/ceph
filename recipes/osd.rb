#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: osd
#
# Copyright 2011, DreamHost Web Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "apt"
include_recipe "btrfs"
include_recipe "parted"
include_recipe "supervisord"
include_recipe "ceph::default"

package "libopen4-rubygem" do
	action :upgrade
end

# Need a script to start the OSD:
# params: journal_dev data_dev osd_id mountpoint
# 1) Check joural dev exists and is accessable
# 2) Check data dev exists and is accessable
# 3) Check mountpoint exists and is accessable
# 4) Mount data dev on mountpoint
# 5) Check for existance of magic file, exit 2 if not found
# 6) Exec OSD process

# Make sure we have a bootstrap key before doing anything else
if (defined? node['ceph']['osd_bootstrap'].nil?)
  raise 'No osd_bootstrap key in environment'
end

directory "/srv/ceph/devices" do
  action :create
  owner "root"
  group "root"
  mode "0755"
end

node['ceph']['osd_devices'].each do |osd_device|
  # Needs mode switch: hold, recreate, create, destroy then call appropriate functions
  if (osd_device['status'] == "create")
    # Build bootstrap keyring
    bootstrap_key = node['ceph']['osd_bootstrap']
    bootstrap_file = Tempfile.new('bootstrap-osd')
    bootstrap_path = bootstrap_file.path
    subprocess 'ceph-authtool', bootstrap_path, '--name=client.bootstrap-osd', '--add-key='+bootstrap_key
    # This device set does not have an osd_id, so create it
    if (defined? osd_device['ceph']['osd_id'].nil?)
      # Get OSD key and id using bootstrap
      osd_id = ''
      Open4::spawn(
                   [
                    'ceph',
                    '-k', bootstrap_path,
                    '-n', 'client.bootstrap-osd',
                    'osd', 'create', '--concise',
                   ],
                   :stdout=>osd_id,
                   :stderr=>STDERR
                   )
      osd_id.chomp!
      raise 'osd id is not numeric' unless /^[0-9]+$/.match(osd_id)
      osd_device['osd_id'] = osd_id
    end
    # Grab a monmap
    monmap = Tempfile.new('monmap')
    subprocess(
               'ceph',
               '-k', bootstrap_path,
               '-n', 'client.bootstrap-osd',
               'mon', 'getmap', '-o', monmap.path
              )
    # Make filesystem
    bash "Format data device for osd_device['osd_id']" do
      code "mkfs.btrfs osd_device['data_dev']"
    end
    bash "Clearing journal device for osd_device['osd_id']" do
      code "dd if=/dev/zero of=osd_device['journal_dev'] bs=1M count=4"
    end

    # Make supervisord config
    # Start via supervisord
    # Reset status flag
    #osd_device['status'] = "hold"

    # Monitor and start OSDs with supervisord
    #node['ceph']['osd_devices'].each do |osd_device|
    #  ceph = supervisord_program "osd #{osd_device['osd_id'}" do
    #    command "osd #{osd_device['osd_id']}"
    #    action [:supervise, :start]
    #  end
    #  ruby_block "start osd #{osd_device}" do
    #    block do
    #      ceph.run_action(:start)
    #   end
    #end

    node['ceph']['osd_devices'].each do |osd_device|
      link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data" do
        to "#{osd_device['data_dev']}"
        link_type :symbolic
      end
      link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.journal" do
        to "#{osd_device['journal_dev']}"
        link_type :symbolic
      end
    end
  end
end

service "ceph" do
	action [:enable,:start]
end
