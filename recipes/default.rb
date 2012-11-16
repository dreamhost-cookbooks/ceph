#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: default
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
include_recipe "ceph::apt"

ceph_packages = %w{
  librados2
  librbd1
  ceph-common
  ceph-common-dbg
  ceph
  ceph-dbg
}

# We can't pin and install in the same loop because of depends

ceph_packages.each do |pkg|
  apt_preference pkg do
    pin "version #{node['ceph']['version']}"
    pin_priority "1001"
  end
  package pkg do
    version node['ceph']['version']
    action :install
    options "--no-install-recommends -o Dpkg::Options::='--force-confold'"
  end
end

directories = %w{
  /etc/cron.hourly
  /var/run/ceph
  /var/log/ceph
  /etc/ceph
}

directories.each do |dir|
  directory dir do
    owner "root"
    group "root"
    mode "0755"
    action :create
  end
end

cookbook_file "/etc/cron.hourly/logrotate" do
  source "logrotate"
  owner "root"
  group "root"
  mode "0755"
end

logrotate_app "ceph" do
  cookbook "logrotate"
  path "/var/log/ceph/*.log"
  frequency "size=200M"
  rotate 9
  create "644 root root"
end
