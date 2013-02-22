#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
#
# Cookbook Name:: ceph
# Recipe:: radosgw
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
include_recipe "ceph::rados-rest"

def randomFileNameSuffix (numberOfRandomchars)
  s = ""
  numberOfRandomchars.times { s << (65 + rand(26))  }
  s
end

apache_packages = %w{
  apache2
  apache2-mpm-worker
  apache2-utils
  apache2.2-bin
  apache2.2-common
}

apache_packages.each do |pkg|
  apt_preference pkg do
    pin "version #{node['ceph']['apache2']['version']}"
    pin_priority "1001"
  end
  package pkg do
    version node['ceph']['apache2']['version']
    action :install
  end
end

include_recipe "apache2"

apt_preference "libapache2-mod-fastcgi" do
  pin "version #{node['ceph']['fastcgi']['version']}"
  pin_priority "1001"
end

package 'libapache2-mod-fastcgi' do
  version node['ceph']['fastcgi']['version']
  action :install
end

# Magic dir/file to enable upstart supervision
directory "/var/lib/ceph/radosgw/ceph-radosgw.#{node['hostname']}" do
  owner "root"
  group "root"
  mode "755"
  recursive true
  action :create
end

file "/var/lib/ceph/radosgw/ceph-radosgw.#{node['hostname']}/done" do
  owner "root"
  group "root"
  mode "0644"
  action :touch
end

# Disable Sys-V startup scripts
service "radosgw" do
  service_name "radosgw"
  action [:disable]
end

service "radosgw-all" do
  provider Chef::Provider::Service::Upstart
  service_name "radosgw-all"
  supports :restart => true
  action [:enable, :start]
end

apache_module "fastcgi" do
  conf true
end

apache_module "rewrite" do
  conf false
end

listen_addr = get_cephnet_ip('loadbal',node)

template "/etc/apache2/sites-available/rgw.conf" do
  source "rgw.conf.erb"
  owner "root"
  group "root"
  mode "0400"
  variables(
    :listen_addr => listen_addr
  )
end

cookbook_file "/etc/logrotate.d/apache2" do
  source "logrotate-apache2"
  owner "root"
  group "root"
  mode "0400"
end

apache_site "rgw.conf" do
  enable enable_setting
end

logrotate_app "radosgw" do
  cookbook "logrotate"
  path "/var/log/ceph/ceph.client.radosgw.*.log"
  frequency "size=200M"
  rotate 9
  create "644 root root"
end

# Setup the radosgw keyring
if(!File.executable?('/usr/bin/ceph'))
  Chef::Log.info("Ceph is not yet installed, will try keyring management again after that's done")
elsif (node['ceph']['admin_key'].nil?)
  Chef::Log.warn("No admin_key key found, Client Keys cannot be managed")
elsif (!File.exists?("/etc/ceph/ceph.conf"))
  Chef::Log.info("Ceph is not yet configured, will try keyring management again later")
elsif (!File.exists?("/etc/ceph/client.radosgw.#{node['hostname']}.keyring"))
  Chef::Log.info("Creating client key for radosgw.#{node['hostname']}")
  bootstrap_path = "/tmp/bootstrap-" + randomFileNameSuffix(7)
  %x{if [ ! -f #{bootstrap_path} ]; then touch #{bootstrap_path}; ceph-authtool #{bootstrap_path} --name=client.admin --add-key='#{node['ceph']['admin_key']}'; fi}

  # client.radosgw.<%= node[:hostname] %>
  # this keyring will be used by the radosgw
  # instances
  hostname = node["hostname"]
  execute 'create client.radosgw.#{hostname} keyring' do
    creates '/etc/ceph/client.radosgw.#{hostname}.keyring'
    command <<-EOH
      set -e
      touch /etc/ceph/client.radosgw.#{hostname}.keyring.tmp
      ceph-authtool \
        --create-keyring \
        --gen-key \
      --name=client.radosgw.#{hostname} \
      /etc/ceph/client.radosgw.#{hostname}.keyring.tmp
      ceph --name client.admin --keyring #{bootstrap_path} \
      auth add client.radosgw.#{hostname} \
      -i /etc/ceph/client.radosgw.#{hostname}.keyring.tmp \
      osd 'allow *' \
      mon 'allow rwx'
      mv /etc/ceph/client.radosgw.#{hostname}.keyring.tmp /etc/ceph/client.radosgw.#{hostname}.keyring
    EOH
    creates '/etc/ceph/client.radosgw.#{hostname}.keyring'
    not_if {File.exists?("/etc/ceph/client.radosgw.#{hostname}.keyring")}
  end

  # Cleanup tempfiles
  file bootstrap_path do
    action :delete
  end
end
