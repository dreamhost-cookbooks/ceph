#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: osd
#
# Copyright 2011, 2012 DreamHost Web Hosting
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
include_recipe "xfs"
include_recipe "runit"
include_recipe "ceph::default"

osd_id = nil

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

  # Common variables to reduce typing
  encrypted = node['ceph']['dmcrypt_osd'] || osd_device['dmcrypt']
  cryptosd_data_device = nil
  cryptosd_journal_device = nil
  osd_data_device = osd_device['data_dev']
  osd_journal_device = osd_device['journal_dev']
  osd_id = nil

  # This device set does not have an osd_id, so create it
  if (osd_device['osd_id'].nil?)
    # Get OSD key and id using bootstrap
    osd_id = %x{ceph -k #{bootstrap_path} -n client.bootstrap-osd osd create --concise}
    osd_id.chomp!
    raise "osd id is not numeric: #{osd_id}" unless /^[0-9]+$/.match(osd_id)
    Chef::Log.info("Will build osd_id " + osd_id)
    osd_device['osd_id'] = osd_id
  else
    osd_id = osd_device['osd_id']
  end

  # Setup encryption if desired
  if ( encrypted == "true" )
    Chef::Log.info("Encryption desired on osd #{osd_id}")
    osd_data_device = "/dev/mapper/cryptosd.#{osd_id}.data"
    osd_journal_device = "/dev/mapper/cryptosd.#{osd_id}.journal"
    cryptosd_data_device = osd_device['data_dev']
    cryptosd_journal_device = osd_device['journal_dev']
    # Ensure the dmcrypt tools are installed
    package "cryptsetup" do
      action :install
    end
    # Build directory to hold keys
    directory "/srv/ceph/dmkey" do
      action :create
      owner "root"
      group "root"
      mode "0700"
    end
    # Generate keys for the two devices
    execute "Create journal device keyfile" do
      creates "/srv/ceph/dmkey/osd.#{osd_id}.journal"
      command "openssl rand -out /srv/ceph/dmkey/osd.#{osd_id}.journal 256"
    end
    execute "Create data device keyfile" do
      creates "/srv/ceph/dmkey/osd.#{osd_id}.data"
      command "openssl rand -out /srv/ceph/dmkey/osd.#{osd_id}.data 256"
    end
    # Encrypt the devices
    execute "Setup encryption on raw journal device" do
      command "cryptsetup luksFormat --cipher aes-cbc-essiv:sha256 --key-size 256 #{cryptosd_journal_device} -d /srv/ceph/dmkey/osd.#{osd_id}.journal -q"
    end
    execute "Setup encryption on raw data device" do
      command "cryptsetup luksFormat --cipher aes-cbc-essiv:sha256 --key-size 256 #{cryptosd_data_device} -d /srv/ceph/dmkey/osd.#{osd_id}.data -q"
    end
    # Open then encrypted devices
    execute "Open plaintext interface for journal device" do
      command "cryptsetup luksOpen #{cryptosd_journal_device} -d /srv/ceph/dmkey/osd.#{osd_id}.journal -q cryptosd.#{osd_id}.journal"
    end
    execute "Open plaintext interface for data device" do
      command "cryptsetup luksOpen #{cryptosd_data_device} -d /srv/ceph/dmkey/osd.#{osd_id}.data -q cryptosd.#{osd_id}.data"
    end
    # Create symlinks to ecnrypted devices
    link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data.encrypted" do
      to "#{cryptosd_data_device}"
      link_type :symbolic
    end
    link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.journal.encrypted" do
      to "#{cryptosd_journal_device}"
      link_type :symbolic
    end
  end

  # Make filesystem
  if (osd_device['filesystem'] || node['ceph']['filesystem'] == 'btrfs')
    mkfs_opts = node['ceph']['mkbtrfs_options'] || osd_device['mkbtrfs_options']
    execute "Format data device for #{osd_device['osd_id']} using btrfs" do
      command "mkfs.btrfs #{mkfs_opts} -L osd.#{osd_device['osd_id']} #{osd_data_device}"
    end
  elsif (osd_device['filesystem'] || node['ceph']['filesystem'] == 'ext4')
    mkfs_opts = node['ceph']['mkext4fs_options'] || osd_device['mkext4fs_options']
    execute "Format data device for #{osd_device['osd_id']} using ext4" do
      command "mkfs.ext4 #{mkfs_opts} -L osd.#{osd_device['osd_id']} #{osd_data_device}"
    end
  else # Default to XFS
    mkfs_opts = node['ceph']['mkxfsfs_options'] || osd_device['mkxfsfs_options']
    execute "Format data device for #{osd_id} using XFS" do
      command "mkfs.xfs -f #{mkfs_opts} -L osd.#{osd_device['osd_id']} #{osd_data_device}"
    end
  end
  execute "Clearing journal device for #{osd_device['osd_id']}" do
    command "dd if=/dev/zero of=#{osd_journal_device} bs=1M count=4"
  end

  # Create symlinks for ceph config
  link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data" do
    to "#{osd_data_device}"
    link_type :symbolic
  end
  link "/srv/ceph/devices/osd.#{osd_device['osd_id']}.journal" do
    to "#{osd_journal_device}"
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
    action [:mount]
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
             osd crush set #{osd_device['osd_id']} osd.#{osd_device['osd_id']} 0 \
             pool=default row=#{node['physical_location']['row']} rack=#{node['physical_location']['rack']} host=#{node['hostname']}"
  end

  # Add and start runit service
  if (encrypted == "true")
    runit_service "osd.#{osd_device['osd_id']}" do
      template_name "osd-dmcrypt"
      log_template_name "osd"
      options({
                'osd_id' => osd_id
              })
    end
  else
    runit_service "osd.#{osd_device['osd_id']}" do
      template_name "osd-plaintext"
      log_template_name "osd"
      options({
                'osd_id' => osd_id
              })
    end
  end


  osd_device['status'] = "hold"
end

def destroy_osd (osd_device, adminkey_path)
  Chef::Log.info("Going to destroy OSD #{osd_device['osd_id']}")
  %x{if [ ! -f #{adminkey_path} ]; then touch #{adminkey_path}; ceph-authtool #{adminkey_path} --name=client.admin \
    --add-key='#{node['ceph']['admin_key']}'; fi}

  # Common variables to reduce typing
  encrypted = node['ceph']['dmcrypt_osd'] || osd_device['dmcrypt']
  cryptosd_data_device = nil
  cryptosd_journal_device = nil
  osd_data_device = osd_device['data_dev']
  osd_journal_device = osd_device['journal_dev']
  osd_id = osd_device['osd_id']

  # Stop the daemon and remove the service
  execute "Stopping osd.#{osd_device['osd_id']}" do
    command "sv stop osd.#{osd_device['osd_id']}"
    returns [0,1]
  end
  directory "/etc/sv/osd.#{osd_device['osd_id']}" do
    recursive true
    action :delete
  end
  file "/etc/service/osd.#{osd_device['osd_id']}" do
    action :delete
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
          osd crush remove osd.#{osd_device['osd_id']}"
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

  # Umount the filesystem
  execute "Umounting data device for OSD #{osd_device['osd_id']}" do
    command "umount /srv/ceph/osd/#{osd_device['osd_id']}"
    returns [0,1]
  end

  # Destroy encryption if required
  if ( encrypted == "true" )
    Chef::Log.info("Encryption cleanup for osd #{osd_id}")
    osd_data_device = "/dev/mapper/cryptosd.#{osd_id}.data"
    osd_journal_device = "/dev/mapper/cryptosd.#{osd_id}.journal"
    cryptosd_data_device = osd_device['data_dev']
    cryptosd_journal_device = osd_device['journal_dev']
    # Build directory to hold keys
    directory "/srv/ceph/dmkey" do
      action :create
      owner "root"
      group "root"
      mode "0700"
    end
    # Close then encrypted devices
    execute "Close plaintext interface for journal device" do
      command "cryptsetup luksClose #{osd_journal_device}"
      returns [0,1,4]
    end
    execute "Close plaintext interface for data device" do
      command "cryptsetup luksClose #{osd_data_device}"
      returns [0,1,4]
    end
    # Remove keys for the two devices
    file "/srv/ceph/dmkey/osd.#{osd_id}.journal" do
      action :delete
    end
    file "/srv/ceph/dmkey/osd.#{osd_id}.data" do
      action :delete
    end
    # Remove links to the encrypted devices
    file "/srv/ceph/devices/osd.#{osd_id}.journal.encrypted" do
      action :delete
    end
    file "/srv/ceph/devices/osd.#{osd_id}.data.encrypted" do
      action :delete
    end
  end

  # Remove symlinks for ceph config (temporary until we get upstart)
  file "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data" do
    action :delete
  end
  file "/srv/ceph/devices/osd.#{osd_device['osd_id']}.journal" do
    action :delete
  end

  # Destroy the directory for the OSD mountpoint exists
  directory "/srv/ceph/osd/#{osd_device['osd_id']}" do
    recursive true
    action :delete
  end

  # Reset status flag
  osd_device['status'] = "hold"
  osd_device['osd_id'] = nil
end

def upgrade_osd (osd_device, adminkey_path)
  Chef::Log.info("Going to upgrade OSD #{osd_device['osd_id']} to new startup system")

  # Disable the ceph service (replaced by runit)
  service "ceph" do
    action :disable
  end
  
  # Stop the daemon and disable the service
  execute "Stopping osd.#{osd_device['osd_id']}" do
    command "service ceph stop osd.#{osd_device['osd_id']}"
    returns [0,1]
  end

  # Remove the fstab entry
  mount "/srv/ceph/osd/#{osd_device['osd_id']}" do
    device "/srv/ceph/devices/osd.#{osd_device['osd_id']}.data"
    options "noatime"
    action [:disable]
  end

  # Install new runit service
  runit_service "osd.#{osd_id}" do
    template_name "osd-plaintext"
    log_template_name "osd"
    options({
              'osd_id' => osd_id
            })
  end

  # Reset status flag
  osd_device['status'] = "hold"
end

# BEGIN RECIPE LOGIC
# Make sure we have a bootstrap key before doing anything else
if(!File.executable?('/usr/bin/ceph'))
  Chef::Log.info("Ceph is not yet installed, will try making OSDs again after that's done")
elsif (node['ceph']['osd_bootstrap'].nil?)
  Chef::Log.warn("No osd_bootstrap key found, OSDs cannot be managed")
elsif (!File.exists?('/etc/ceph/ceph.conf'))
  Chef::Log.warn("No ceph configuration, will try making OSDs again after that's done")
else
  directories = %w{
    /srv/ceph
    /srv/ceph/devices
    /srv/ceph/osd
  }

  directories.each do |dir|
    directory dir do
      action :create
      owner "root"
      group "root"
      mode "0755"
    end
  end

  # Setup bootstrap keyring
  bootstrap_key = node['ceph']['osd_bootstrap']
  bootstrap_path = "/tmp/bootstrap-osd-" + randomFileNameSuffix(7)

  # Setup a monmap
  monmap_path = "/tmp/monmap-" + randomFileNameSuffix(7)

  # Setup an admin key
  adminkey_path = "/tmp/adminkey-" + randomFileNameSuffix(7)

  # This should store the osd_id data before we head off into the fray
  node.save

  node['ceph']['osd_devices'].each do |osd_device|
    # Handle status switch: hold, recreate, create, destroy then call appropriate functions.
    #  Status hold does nothing
    if (osd_device['status'] == "create")
      create_osd(osd_device, bootstrap_key, bootstrap_path, monmap_path)
    elsif (osd_device['status'] == "destroy" && /^[0-9]+$/.match(osd_device['osd_id']))
      destroy_osd(osd_device, adminkey_path)
    elsif (osd_device['status'] == "upgrade" && /^[0-9]+$/.match(osd_device['osd_id']))
      upgrade_osd(osd_device, adminkey_path)
    elsif (osd_device['status'] == "recreate" && /^[0-9]+$/.match(osd_device['osd_id']))
      Chef::Log.info("About to recreate OSD #{osd_device['osd_id']} by destroying then creating it")
      destroy_osd(osd_device, adminkey_path)
      create_osd(osd_device, bootstrap_key, bootstrap_path, monmap_path)
    end #status==create
    # Prevent bum chef runs from messing up the works.
    node.save
  end

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
end
