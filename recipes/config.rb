# Cookbook Name:: ceph
# Recipe:: config
#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
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

# Grab any OSD devices on this node
osd_devices = []
if (! node["ceph"]["osd_devices"].nil?) then
  node["ceph"]["osd_devices"].each do |osd_device|
    if (! osd_device['osd_id'].nil?)
      osd_devices << osd_device
    end
  end
end

mon_initial_members = node["ceph"]["mon_initial_members"].split(",")
mon_host = String.new
mon_pool = search(:node, 'run_list:recipe\[ceph\:\:mon\] AND ' +  %Q{chef_environment:"#{node.chef_environment}"})
mon_pool.each do |monitor|
  mh = mon_host << get_cephnet_ip("public", monitor) << ","
  mon_host = mh
end
mon_host_array = mon_host.split(",")

raise "Ceph mon_count no set" unless node["ceph"]["mon_count"]
raise "Ceph mon_count does not match mon_initial_members" unless node["ceph"]["mon_count"] == mon_initial_members.length

Chef::Log.info("mon_initial_members: #{mon_initial_members}")
Chef::Log.info("mon_host: #{mon_host}")

# Am I a RESTful RADOS Gateway?
is_radosgw = 0
node.run_list.each do |matching|
  if (matching == "recipe[ceph::radosgw]")
    is_radosgw = 1
  end
end

directory "/etc/ceph" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

template "/etc/ceph/ceph.conf" do
  source "ceph.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :mon_host => mon_host,
    :osd_devices => osd_devices,
    :public_ip => public_ip,
    :cluster_ip => cluster_ip,
    :is_radosgw => is_radosgw
  )
end
