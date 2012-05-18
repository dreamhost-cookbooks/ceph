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

osd_id = nil

include_recipe "apt"
include_recipe "btrfs"
include_recipe "parted"
#include_recipe "supervisord"
include_recipe "ceph::default"

# Need a script to start the OSD:
# params: journal_dev data_dev osd_id mountpoint
# 1) Check joural dev exists and is accessable
# 2) Check data dev exists and is accessable
# 3) Check mountpoint exists and is accessable
# 4) Mount data dev on mountpoint
# 5) Check for existance of magic file, exit 2 if not found
# 6) Exec OSD process

def randomFileNameSuffix (numberOfRandomchars)
  s = ""
  numberOfRandomchars.times { s << (65 + rand(26))  }
  s
end

def create_osd (osd_device, bootstrap_key, bootstrap_path, monmap_path)
  Chef::Log.info("Going to create a new OSD for #{osd_device['data_dev']}")
  #Chef::Log.info("About to create keyring at #{bootstrap_path} with #{bootstrap_key}")
  %x{if [ ! -f #{bootstrap_path} ]; then touch #{bootstrap_path}; ceph-authtool #{bootstrap_path} --name=client.bootstrap-osd --add-key='#{bootstrap_key}'; fi}
  #Chef::Log.info("About to download monmap to #{monmap_path}")
  %x{if [ ! -f #{monmap_path} ]; then ceph -k #{bootstrap_path} -n client.bootstrap-osd mon getmap -o #{monmap_path}; fi}
  
  # This device set does not have an osd_id, so create it
  if (osd_device['osd_id'].nil?)
    # Get OSD key and id using bootstrap
    osd_id = %x{ceph -k #{bootstrap_path} -n client.bootstrap-osd osd create --concise}
    osd_id.chomp!
    raise "osd id is not numeric: #{osd_id}" unless /^[0-9]+$/.match(osd_id)
    Chef::Log.info("Will build osd_id " + osd_id)
    osd_device['osd_id'] = osd_id
  end
  # Make filesystem
  if (osd_device['filesystem'] || node['ceph']['filesystem'] == 'btrfs')
    mkfs_opts = node['ceph']['mkbtrfs_options'] || osd_device['mkbtrfs_options']
    execute "Format data device for #{osd_device['osd_id']} using btrfs" do
      command "mkfs.btrfs #{mkfs_opts} -L osd.#{osd_device['osd_id']} #{osd_device['data_dev']}"
    end
  elsif (osd_device['filesystem'] || node['ceph']['filesystem'] == 'ext4')
    mkfs_opts = node['ceph']['mkext4fs_options'] || osd_device['mkext4fs_options']
    execute "Format data device for #{osd_device['osd_id']} using ext4" do
      command "mkfs.ext4 #{mkfs_opts} -L osd.#{osd_device['osd_id']} #{osd_device['data_dev']}"
    end
  else # Default to XFS
    mkfs_opts = node['ceph']['mkxfsfs_options'] || osd_device['mkxfsfs_options']
    execute "Format data device for #{osd_id} using XFS" do
      command "mkfs.xfs -f #{mkfs_opts} -L osd.#{osd_device['osd_id']} #{osd_device['data_dev']}"
    end
  end
  execute "Clearing journal device for #{osd_device['osd_id']}" do
    command "dd if=/dev/zero of=#{osd_device['journal_dev']} bs=1M count=4"
  end
  
  # Create symlinks for ceph config (temporary until we get supervisord)
  link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data" do
    to "#{osd_device['data_dev']}"
    link_type :symbolic
  end
  link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.journal" do
    to "#{osd_device['journal_dev']}"
    link_type :symbolic
  end
  
  # Ensure the directory for the OSD mountpoint exists
  directory "/srv/ceph/osd/#{osd_device['osd_id']}" do
    owner "root"
    group "root"
    mode "0755"
    action :create
  end
  
  # Mount the filesystem
  mount "/srv/ceph/osd/#{osd_device['osd_id']}" do
    device "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data"
    options "noatime"
    action [:mount, :enable]
  end
  
  # Make the ceph stuff on the new mountpoint
  execute "Ceph mkfs on the data filesystem for #{osd_device['osd_id']}" do
    command "ceph-osd --mkfs --mkkey -i #{osd_device['osd_id']} --monmap #{monmap_path}"
  end
  
  # Create keyring for osd
  execute "Create keyring for #{osd_device['osd_id']}" do
    command "ceph --name client.bootstrap-osd --keyring #{bootstrap_path} \
                auth add osd.#{osd_device['osd_id']} \
                -i /srv/ceph/osd/#{osd_device['osd_id']}/keyring \
                osd 'allow *' \
                mon 'allow rwx'"
  end
  
  # Add to crushmap
  execute "Adding OSD #{osd_device['osd_id']} to crushmap at #{node['physical_location']['row']}:#{node['physical_location']['rack']}:#{node['hostname']}" do
    command "ceph --name client.bootstrap-osd --keyring #{bootstrap_path} \
                osd crush add #{osd_device['osd_id']} osd.#{osd_device['osd_id']} 1 \
                pool=default row=#{node['physical_location']['row']} rack=#{node['physical_location']['rack']} host=#{node['hostname']}"
  end
  
  # Make supervisord config
  # Start via supervisord
  # Reset status flag
  osd_device['status'] = "hold"
  
  # Monitor and start OSDs with supervisord
  #node['ceph']['osd_devices'].each do |osd_device|
  #  ceph = supervisord_program "osd #{osd_device['osd_id']}" do
  #    command "osd #{osd_device['osd_id']}"
  #    action [:supervise, :start]
  #  end
  #  ruby_block "start osd #{osd_device}" do
  #    block do
  #      ceph.run_action(:start)
  #   end
  #end
end

def destroy_osd (osd_device, adminkey_path)
  Chef::Log.info("Going to destroy OSD #{osd_device['osd_id']}")
  %x{if [ ! -f #{adminkey_path} ]; then touch #{adminkey_path}; ceph-authtool #{adminkey_path} --name=client.admin \
--add-key='#{node['ceph']['admin_key']}'; fi}

  # Stop the daemon and disable the service
  execute "Stopping osd.#{osd_device['osd_id']}" do
    command "service ceph stop osd.#{osd_device['osd_id']}"
    returns [0,1]
  end
  
  # Mark this osd as unused
  if (! osd_device['osd_id'].nil?)
    # Take OSD down
    execute "Take OSD #{osd_device['osd_id']} down" do
      command "ceph --name client.admin --keyring #{adminkey_path} \
                osd down #{osd_device['osd_id']}"
      returns [0,1]
    end
    # Take OSD out
    execute "Take OSD #{osd_device['osd_id']} out" do
      command "ceph --name client.admin --keyring #{adminkey_path} \
                osd out #{osd_device['osd_id']}"
      returns [0,1]
    end
    # Remove from crushmap
    execute "Removing OSD #{osd_device['osd_id']} to crushmap at #{node['physical_location']['row']}:#{node['physical_location']['rack']}:#{node['hostname']}" do
      command "ceph --name client.admin --keyring #{adminkey_path} \
                osd crush remove #{osd_device['osd_id']}"
      returns [0,1]
    end
    # Remove OSD from OSD Map
    execute "Remove OSD #{osd_device['osd_id']} from OSD Map" do
      command "ceph --name client.admin --keyring #{adminkey_path} \
                osd rm #{osd_device['osd_id']}"
      returns [0,1]
    end
    # Remove OSD key
    execute "Remove OSD #{osd_device['osd_id']} key" do
      command "ceph --name client.admin --keyring #{adminkey_path} \
                auth del osd.#{osd_device['osd_id']}"
      returns [0,1]
    end
  end
  
  # Remove the fstab entry
  mount "/srv/ceph/osd/#{osd_device['osd_id']}" do
    device "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data"
    options "noatime"
    action [:disable]
  end
  
  # Remove symlinks for ceph config (temporary until we get supervisord)
  link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data" do
    to "#{osd_device['data_dev']}"
    link_type :symbolic
    action :delete
  end
  link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.journal" do
    to "#{osd_device['journal_dev']}"
    link_type :symbolic
    action :delete
  end

  # Umount the filesystem
  execute "Umounting data device for OSD #{osd_device['osd_id']}" do
    command "umount /srv/ceph/osd/#{osd_device['osd_id']}"
    returns [0,1]
  end
  
  # Destroy the directory for the OSD mountpoint exists
  directory "/srv/ceph/osd/#{osd_device['osd_id']}" do
    recursive true
    action :delete
  end
  
  
  # Make supervisord config
  # Start via supervisord
  # Reset status flag
  osd_device['status'] = "hold"
  
  # Monitor and start OSDs with supervisord
  #node['ceph']['osd_devices'].each do |osd_device|
  #  ceph = supervisord_program "osd #{osd_device['osd_id']}" do
  #    command "osd #{osd_device['osd_id']}"
  #    action [:supervise, :start]
  #  end
  #  ruby_block "start osd #{osd_device}" do
  #    block do
  #      ceph.run_action(:start)
  #   end
  #end

  osd_device['osd_id'] = nil

end

# BEGIN RECIPE LOGIC
# Make sure we have a bootstrap key before doing anything else
if(!File.executable?('/usr/bin/ceph'))
  Chef::Log.info("Ceph is not yet installed, will try making OSDs again after that's done")
elsif (node['ceph']['osd_bootstrap'].nil?)
  Chef::Log.warn("No osd_bootstrap key found, OSDs cannot be managed")
else

  directory "/srv/ceph" do
    action :create
    owner "root"
    group "root"
    mode "0755"
  end

  directory "/srv/ceph/devices" do
    action :create
    owner "root"
    group "root"
    mode "0755"
  end

  directory "/srv/ceph/osd" do
    action :create
    owner "root"
    group "root"
    mode "0755"
  end

  # Setup bootstrap keyring
  bootstrap_key = node['ceph']['osd_bootstrap']
  bootstrap_path = "/tmp/bootstrap-osd-" + randomFileNameSuffix(7)
  # Setup a monmap
  monmap_path = "/tmp/monmap-" + randomFileNameSuffix(7)
  # Setup an admin key
  adminkey_path = "/tmp/adminkey-" + randomFileNameSuffix(7)

  node.save # This should store the osd_id data before we head off into the fray1

  node['ceph']['osd_devices'].each do |osd_device|
    # Handle status switch: hold, recreate, create, destroy then call appropriate functions.
    #  Status hold does nothing
    if (osd_device['status'] == "create")
      create_osd(osd_device, bootstrap_key, bootstrap_path, monmap_path)
    elsif (osd_device['status'] == "destroy" && /^[0-9]+$/.match(osd_device['osd_id']))
      destroy_osd(osd_device, adminkey_path)
    elsif (osd_device['status'] == "recreate" && /^[0-9]+$/.match(osd_device['osd_id']))
      Chef::Log.info("About to recreate OSD #{osd_device['osd_id']} by destroying then creating it")
      destroy_osd(osd_device, adminkey_oath)
      create_osd(osd_device, bootstrap_key, bootstrap_path, monmap_path)
    end #status==create
    node.save # Prevent bum chef runs from messing up the works.
  end #osd_device

  # Cleanup tempfiles
  file monmap_path do
    action :delete
  end
  file bootstrap_path do
    action :delete
  end
  file adminkey_path do
    action :delete
  end

end #osd_bootstrap
