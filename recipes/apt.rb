#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: apt
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

apt_repository "ceph" do
	uri node['ceph']['repo_uri']
	distribution node['lsb']['codename']
	components ["main"]
	key "https://raw.github.com/ceph/ceph/master/keys/autobuild.asc"
	action :add
end

apt_repository "ceph-apache2" do
	uri node['ceph']['apache2_repo_uri']
	distribution node['lsb']['codename']
	components ["main"]
	key "https://raw.github.com/ceph/ceph/master/keys/autobuild.asc"
	action :add
end

apt_repository "ceph-fastcgi" do
	uri node['ceph']['fastcgi_repo_uri']
	distribution node['lsb']['codename']
	components ["main"]
	key "https://raw.github.com/ceph/ceph/master/keys/autobuild.asc"
	action :add
end
