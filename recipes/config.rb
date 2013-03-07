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

# Get monitor ips and hostnames
mon_initial_members = String.new
mon_host = String.new
mon_pool = search(:node, 'run_list:recipe\[ceph\:\:mon\] AND ' +  %Q{chef_environment:"#{node.chef_environment}"})
mon_pool.each do |monitor|
  mh = mon_host <<  get_cephnet_ip("public",monitor) << ","
  mon_host = mh
  mim = mon_initial_members << monitor.hostname << ","
  mon_initial_members = mim
end

Chef::Log.info("mon_initial_members: #{mon_initial_members}")
Chef::Log.info("mon_host: #{mon_host}")

# Get cluster ips if I'm an OSD
public_ip = ""
cluster_ip = ""
node.run_list.each do |matching|
  if (matching == "recipe[ceph::osd]")
    public_ip = get_cephnet_ip("public",node)
    cluster_ip = get_cephnet_ip("cluster",node)
  end
end

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
    :mon_host => mon_host[0..-2],
    :mon_initial_members => mon_initial_members[0..-2],
    :osd_devices => osd_devices,
    :public_ip => public_ip,
    :cluster_ip => cluster_ip,
    :is_radosgw => is_radosgw
  )
end
