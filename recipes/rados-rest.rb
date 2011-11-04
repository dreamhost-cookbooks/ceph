#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: rados-client
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
		        
include_recipe "apt"

apt_repository "ceph" do
	uri "http://deploy.benjamin.dhobjects.net/ceph/combined/"
	distribution node['lsb']['codename']
	components ["main"]
	key "http://ceph.newdream.net/03C3951A.asc"
	action :add
end

packages = %w{
	librados2
	librgw1
	librbd1
	ceph-common
	ceph-common-dbg
	radosgw
	radosgw-dbg
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
