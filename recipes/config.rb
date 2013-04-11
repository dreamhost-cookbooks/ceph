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
    :is_radosgw => is_radosgw
  )
end
