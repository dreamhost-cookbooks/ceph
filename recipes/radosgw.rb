#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: radosgw
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
include_recipe "ceph::rados-rest"

apt_repository "ceph-apache2" do
    uri "http://deploy.benjamin.dhobjects.net/apache2/combined/"
    distribution node['lsb']['codename']
    components ["main"]
    key "http://ceph.newdream.net/03C3951A.asc"
    action :add
end

apt_repository "ceph-fastcgi" do
    uri "http://deploy.benjamin.dhobjects.net/libapache-mod-fastcgi/combined/"
    distribution node['lsb']['codename']
    components ["main"]
    key "http://ceph.newdream.net/03C3951A.asc"
    action :add
end

packages = %w{
	apache2
	apache2-mpm-worker
	apache2-utils
	apache2.2-bin
	apache2.2-common
	libapache2-mod-fastcgi
}

packages.each do |pkg|
	template "/etc/apt/preferences.d/" + pkg + "-1001" do
		source "apache-pin.erb"
		variables({
			:package => pkg 
		})
	end 
end

include_recipe "apache2"

packages.each do |pkg|
	package pkg do 
		action :upgrade
	end
end

service "radosgw" do
	service_name "radosgw"
	supports :restart => true
	action[:enable,:start]
end

apache_module "fastcgi" do
	conf true
end

apache_module "rewrite" do
	conf false
end

template "/etc/apache2/sites-available/rgw.conf" do
	source "rgw.conf.erb"
	mode 0400
	owner "root"
	group "root"
	variables(
		:ceph_api_fqdn => node[:ceph][:api_fqdn],
		:ceph_admin_email => node[:ceph][:admin_email],
		:ceph_rgw_addr => node[:ceph][:rgw_addr]
	)
	if ::File.exists?("#{node[:apache][:dir]}/sites-enabled/rgw.conf")
		notifies :restart, "service[apache2]"
	end
end

apache_site "rgw.conf" do
	enable enable_setting
end

