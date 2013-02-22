#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
#
# Cookbook Name:: ceph
# Recipe:: client
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

def randomFileNameSuffix (numberOfRandomchars)
  s = ""
  numberOfRandomchars.times { s << (65 + rand(26))  }
  s
end

logrotate_app "ceph-client" do
  cookbook "logrotate"
  path "/var/log/ceph/ceph.client.*.log"
  frequency "size=200M"
  rotate 9
  create "644 root root"
end

# Setup the radosgw keyring
if(!File.executable?("/usr/bin/ceph"))
  Chef::Log.info("Ceph is not yet installed, will try keyring management again after that's done")
elsif (node["ceph"]["admin_key"].nil?)
  Chef::Log.warn("No admin_key key found, Client Keys cannot be managed")
elsif (!File.exists?("/etc/ceph/ceph.conf"))
  Chef::Log.info("Ceph is not yet configured, will try keyring management again later")
elsif (!File.exists?("/etc/ceph/client.radosgw.#{node['hostname']}.keyring"))
  Chef::Log.info("Creating client key for radosgw.#{node['hostname']}")
  bootstrap_path = "/tmp/bootstrap-" + randomFileNameSuffix(7)
  %x{if [ ! -f #{bootstrap_path} ]; then touch #{bootstrap_path}; ceph-authtool #{bootstrap_path} --name=client.admin --add-key='#{node["ceph"]["admin_key"]}'; fi}

  # client.radosgw.<%= node[:hostname] %>
  # this keyring will be used by clients on this host
  # instances
  hostname = node["hostname"]
  execute "create client.#{hostname} keyring" do
    creates '/etc/ceph/client.#{hostname}.keyring'
    command <<-EOH
set -e
touch /etc/ceph/client.#{hostname}.keyring.tmp
ceph-authtool \
  --create-keyring \
  --gen-key \
  --name=client.#{hostname} \
  /etc/ceph/client.#{hostname}.keyring.tmp
ceph --name client.admin --keyring #{bootstrap_path} \
  auth add client.#{hostname} \
  -i /etc/ceph/client.#{hostname}.keyring.tmp \
  osd 'allow *' \
  mon 'allow rwx'
mv /etc/ceph/client.#{hostname}.keyring.tmp /etc/ceph/client.#{hostname}.keyring
EOH
    creates '/etc/ceph/client.#{hostname}.keyring'
    not_if {File.exists?("/etc/ceph/client.#{hostname}.keyring")}
  end

  # Cleanup tempfiles
  file bootstrap_path do
    action :delete
  end

end #keyring
