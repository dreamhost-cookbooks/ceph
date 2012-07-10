#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: rados-client
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

radosgw_packages = %w{
	librados2
	radosgw
	radosgw-dbg
}

radosgw_packages.each do |pkg|
	apt_preference pkg do
		pin "version #{node['ceph']['version']}"
		pin_priority "1001"
	end
	package pkg do
		version node['ceph']['radosgw']['version']
		action :install
		options "-o Dpkg::Options::='--force-confold'"
	end
end
