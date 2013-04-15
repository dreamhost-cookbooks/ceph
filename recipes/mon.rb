#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
#
# Cookbook Name:: ceph
# Recipe:: mon
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
include_recipe "ntp"
include_recipe "ceph::rados"
include_recipe "ceph::config"


directory "/var/lib/ceph/mon/ceph-#{node['hostname']}" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

file "/var/lib/ceph/mon/ceph-#{node.hostname}/upstart" do
  owner "root"
  group "root"
  mode "0644"
  action :touch
end

service "ceph" do
  service_name "ceph"
  action :disable
end

service "ceph-mon-all-starter" do
  provider Chef::Provider::Service::Upstart
  supports :restart => true
  action :enable
end

if !File.exists?("/var/lib/ceph/mon/ceph-#{node.hostname}/done")
  if node.has_key? "ceph"
    if node["ceph"].has_key? "mon_keyring"
      mon_keyring = node['ceph']['mon_keyring']
      template "/var/lib/ceph/mon/ceph-#{node['hostname']}/keyring" do
        source "mon-ceph.keyring.erb"
        owner "root"
        group "root"
        mode "0600"
        variables(
          :mon_keyring => mon_keyring
        )
      end
      execute "Initializing Ceph monitor" do
        command "/usr/bin/ceph-mon --mkfs -i #{node['hostname']} -k /var/lib/ceph/mon/ceph-#{node['hostname']}/keyring && touch /var/lib/ceph/mon/ceph-#{node.hostname}/done"
        action :run
        not_if "test -f /var/lib/ceph/mon/ceph-#{node.hostname}/done"
        notifies :start, "service[ceph-mon-all-starter]", :immediately
      end
    else
      ruby_block "Generate keyring" do
        block do
          mon_keyring = %x{/usr/bin/ceph-authtool -p --gen-print-key -n mon.}
          Chef::Log.error("Couldn't generate monitor keyring")
        end
      end
      template "/var/lib/ceph/mon/ceph-#{node['hostname']}/keyring" do
        source "mon-ceph.keyring.erb"
        owner "root"
        group "root"
        mode "0600"
        variables(
          :mon_keyring => mon_keyring
        )
        not_if "test -f /var/lib/ceph/mon/ceph-#{node['hostname']}/keyring"
      end
    end
  else
    Chef::Log.error("No Ceph node attributes")
    raise error
  end

  execute "Create OSD and admin keys" do
    command "ceph-create-keys -i #{node['hostname']}"
    Chef::Log.error("Couldn't create keyrings!") unless $?.exitstatus == 0
    action :run
    not_if do
      File.exists?("/var/lib/ceph/bootstrap-osd/ceph.keyring")
    end
  end
end

ruby_block "Slurp Ceph keys and set overrides" do
  block do
    node.normal["ceph"]["bootstrap_osd_key"] = File.read("/var/lib/ceph/bootstrap-osd/ceph.keyring")
    Chef::Log.error("Couldn't slurp Ceph OSD keyring!") unless $?.exitstatus == 0
    node.normal["ceph"]["admin_key"] = File.read("/etc/ceph/ceph.client.admin.keyring")
    Chef::Log.error("Couldn't slurp Ceph admin keyring!") unless $?.exitstatus == 0
  end
end
