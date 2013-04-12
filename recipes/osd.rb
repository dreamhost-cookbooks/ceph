#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
#
# Cookbook Name:: ceph
# Recipe:: osd
#
# Copyright 2011-2013 New Dream Network, LLC.
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
include_recipe "ceph::config"
include_recipe "ceph::admin"

# Preparation for dmcrypt OSDs
package "cryptsetup" do
  action :install
end
directory "/etc/ceph/dmcrypt-keys" do
  owner "root"
  group "root"
  mode "0700"
  action :create
end

# Install gdisk and parted for ceph-disk-prepare.
# This should be fixed later by fixing the depends
# in the ceph package.
["gdisk", "parted"].each do |pkg|
  package pkg do
    action :install
  end
end

# Disable System-V init scripts and enable
# upstart supervision for Ceph OSD daemons.
service "ceph" do
  service_name "ceph"
  action :disable
end
service "ceph-osd-all" do
  provider Chef::Provider::Service::Upstart
  service_name "ceph-osd-all"
  supports :restart => true
  action :enable
end

# Search for Ceph monitors
mons = search(:node, 'run_list:recipe\[ceph\:\:mon\] AND ' +  %Q{chef_environment:"#{node.chef_environment}"})

# Inject bootstrap key for new Ceph OSDs
file "/var/lib/ceph/bootstrap-osd/ceph.keyring" do
  content mons[0]["ceph"]["bootstrap_osd_key"]
  action :create
  not_if do
    mons[0]["ceph"]["bootstrap_osd_key"].nil?
  end
  notifies :start, "service[ceph-osd-all]", :immediately
end

# Iterate through OSD devices on this node and take one of three
# actions: create, zapdisk, hold
# 
# create   - Create a new OSD
# recreate - Destroy and recreate an OSD
# zapdisk  - Prepare disk ignoring existing partitions
# hold     - Do nothing
#
node["ceph"]["osd_devices"].each_with_index do |osd_device,index|
  if osd_device["encrypted"] == true
    encrypted = "--dmcrypt"
  else
    encrypted = ""
  end
  if (osd_device["status"] == "create")
    execute "Creating Ceph OSD on #{osd_device['device']}" do
      command "ceph-disk-prepare #{encrypted} #{osd_device['device']}"
      action :run
      notifies :start, "service[ceph-osd-all]", :immediately
    end
  elsif (osd_device["status"] == "zapdisk")
    execute "Creating Ceph OSD on #{osd_device['device']}" do
      command "ceph-disk-prepare #{encrypted} --zap-disk #{osd_device['device']}"
      action :run
      notifies :start, "service[ceph-osd-all]", :immediately
    end
  elsif (osd_device["status"] == "recreate")
    if (osd_device['encrypted'] == true)
      data_uuid = %x{ sgdisk -i 1 #{osd_device['device']} | grep 'unique GUID' | awk '{print $4}' | tail -n1 }.downcase.chomp
      journal_uuid = %x{ sgdisk -i 2 #{osd_device['device']} | grep 'unique GUID' | awk '{print $4}' | tail -n1 }.downcase.chomp
      mount_path = "/dev/mapper/" + data_uuid
      osd_id = %x{ cat $(grep #{data_uuid} /etc/mtab | awk '{print $2}')/whoami }.chomp
    else
      osd_id = %x{ cat $(grep #{osd_device['device']} /etc/mtab | awk '{print $2}'/whoami }.chomp
    end
    execute "Stop ceph-osd: osd.#{osd_id}" do
      command "stop ceph-osd id=#{osd_id}"
    end
    execute "Marking down osd.#{osd_id}" do
      command "ceph osd down #{osd_id}"
    end
    execute "Marking out osd.#{osd_id}" do
      command "ceph osd out #{osd_id}"
    end
    execute "Remove osd.#{osd_id} from cluster" do
      command "ceph osd rm #{osd_id}"
    end
    execute "Remove osd.#{osd_id} from crush" do
      command "ceph osd crush rm osd.#{osd_id}"
    end
    execute "Unmount volumes" do
      command "umount /var/lib/ceph/osd/ceph-#{osd_id}"
    end
    execute "Remove device mapper data device" do
      command "cryptsetup remove #{data_uuid}"
      only_if {osd_device['encrypted'] == true}
    end
    execute "Remove device mapper journal device" do
      command "cryptsetup remove #{journal_uuid}"
      only_if {osd_device['encrypted'] == true}
    end
    execute "Creating Ceph OSD on #{osd_device['device']}" do
      command "ceph-disk-prepare #{encrypted} --zap-disk #{osd_device['device']}"
      action :run
      notifies :start, "service[ceph-osd-all]", :immediately
    end
  end
  node.normal["ceph"]["osd_devices"][index]["device"] = node["ceph"]["osd_devices"][index]["device"]
  node.normal["ceph"]["osd_devices"][index]["encrypted"] = node["ceph"]["osd_devices"][index]["encrypted"]
  node.normal["ceph"]["osd_devices"][index]["filesystem"] = node["ceph"]["osd_devices"][index]["filesystem"]
  node.normal["ceph"]["osd_devices"][index]["status"] = "hold"
  node.save
end
