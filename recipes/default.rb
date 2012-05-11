#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: default
#
# Copyright 2011, DreamHost.com
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

apt_repository "ceph" do
  uri "http://deploy.benjamin.dhobjects.net/ceph-#{node['lsb']['codename']}/combined/"
  distribution node['lsb']['codename']
  components ["main"]
  key "https://raw.github.com/ceph/ceph/master/keys/autobuild.asc"
  action :add
end

packages = %w{
	ceph
	ceph-dbg
	ceph-common
	ceph-common-dbg
	librbd1
	librados2
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
		action :upgrade
	end
end

logrotate_app "ceph" do
	cookbook "logrotate"
	path "/var/log/ceph/*.log"
	frequency "daily"
	rotate 9
	create "644 root root"
end

directory "/etc/ceph" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

directory "/var/run/ceph" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

directory "/var/log/ceph" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end
