#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
#
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
include_recipe "ceph::default"

def create_osd (osd_device)
  Chef::Log.info("Initializaing Ceph OSD with #{osd_device['device']}")
  if (osd_device['filesystem'] == 'btrfs' and osd_device['encrypted'] == true)
    execute "Ceph Encrypted Disk Preparation with btrfs" do
      command "setlock -n /tmp/create-#{osd_device['device'].gsub(/\//, '')} ceph-disk-prepare --type btrfs --dmcrypt #{osd_device['device']}"
      action :run
    end
  elsif (osd_device['filesystem'] == 'btrfs' and osd_device['encrypted'] == false)
    execute "Ceph Disk Preparation with btrfs" do
      command "setlock -n /tmp/create-#{osd_device['device'].gsub(/\//, '')} ceph-disk-prepare --type btrfs #{osd_device['device']}"
      action :run
    end
  elsif (osd_device['filesystem'] == 'ext4' and osd_device['encrypted'] == true)
    execute "Ceph Encrypted Disk Preparation with ext4" do
      command "setlock -n /tmp/create-#{osd_device['device'].gsub(/\//, '')} ceph-disk-prepare --type btrfs --dmcrypt #{osd_device['device']}"
      action :run
    end
  elsif (osd_device['filesystem'] == 'ext4' and osd_device['encrypted'] == false)
    execute "Ceph Disk Preparation with ext4" do
      command "setlock -n /tmp/create-#{osd_device['device'].gsub(/\//, '')} ceph-disk-prepare --type btrfs #{osd_device['device']}"
      action :run
    end
  elsif (osd_device['encrypted'] == true)
    execute "Ceph Encrypted Disk Preparation with xfs" do
      command "setlock -n /tmp/create-#{osd_device['device'].gsub(/\//, '')} ceph-disk-prepare --type xfs --dmcrypt #{osd_device['device']}"
      action :run
    end
  else
    execute "Ceph Disk Prepare Preparation with xfs" do
      command "setlock -n /tmp/create-#{osd_device['device'].gsub(/\//, '')} ceph-disk-prepare --type xfs #{osd_device['device']}"
      action :run
    end
  end
  # reset status
  osd_device['status'] = "hold"
end

def recreate_osd(osd_device)
    Chef::Log.info("Just kidding, not implemented yet")
  osd_device['status'] = "hold"
end

# install cryptsetup for dmcrypt
package "cryptsetup" do
  action :install
end

node['ceph']['osd_devices'].each do |osd_device|
  # do nothing if osd_device status = hold
  if (osd_device['status'] == "create")
    create_osd(osd_device)
  elsif (osd_device['status'] == "recreate")
    Chef::Log.info("Recreating Ceph OSD #{osd_device['device']}")
  end
  node.save
end

service "ceph" do
  service_name "ceph"
  action [:disable]
end

service "ceph-osd-all" do
  provider Chef::Provider::Service::Upstart
  service_name "ceph-osd-all"
  supports :restart => true
  action [:enable, :start]
end
