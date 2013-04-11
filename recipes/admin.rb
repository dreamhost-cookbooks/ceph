#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
#
# Cookbook Name:: ceph
# Recipe:: admin
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
include_recipe "ceph::rados"

package "python-simplejson" do
  action :upgrade
end

package "python-tz" do
  action :upgrade
end

mons = search(:node, 'run_list:recipe\[ceph\:\:mon\] AND ' +  %Q{chef_environment:"#{node.chef_environment}"})

if mons[0]["ceph"]["admin_key"]
  file "/etc/ceph/ceph.client.admin.keyring" do
    content mons[0]["ceph"]["admin_key"]
    owner "root"
    group "root"
    mode "0600"
    action :create
  end
end
