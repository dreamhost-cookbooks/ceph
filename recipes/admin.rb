#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: admin
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
include_recipe "ceph::rados-rest"

packages = %w{ 
	librbd1
	ceph-common
	ceph-common-dbg
	python-simplejson
}

packages.each do |pkg|
    template "/etc/apt/preferences.d/" + pkg + "-1001" do
        source "pin.erb"
        variables({
            :package => pkg 
        })
    end 
end

packages.each do |pkg|
    package pkg do
        version = node['ceph']['version']
        action :upgrade
    end 
end

if (node['ceph']['admin_key'].nil?) then
  Chef::Log.info("No admin key available for creating keyring")
else
  execute "create admin keyring" do
    command "ceph-authtool -C /etc/ceph/client.admin.keyring --name=client.admin --add-key='#{node['ceph']['admin_key']}'"
    creates "/etc/ceph/client.admin.keyring"
    action :run
  end
end
