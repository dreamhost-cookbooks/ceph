#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Author:: Carl Perry <carl.perry@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: mon
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

def randomFileNameSuffix (numberOfRandomchars)
	s = ""
	numberOfRandomchars.times { s << (65 + rand(26))  }
	s
end

# Automated monitor creation
if (node['ceph']['mon_bootstrap'].nil? || node['ceph']['fsid'].nil?)
	Chef::Log.warn("No mon_bootstrap key and/or fsid found, run /etc/ceph/initial-cluster-setup.sh")
	monitor_ip = get_if_ip_for_net('storage',node)
	template '/etc/ceph/initial-cluster-setup.sh' do
		source 'inital-cluster-setup.sh.erb'
		mode '0500'
		variables(
			:monitor_ip => monitor_ip,
		)
	end
	cookbook_file '/etc/ceph/chef-crushmap.txt' do
		source 'crushmap.txt'
		mode '0400'
	end
else
	Chef::Log.info("The mon_bootstrap key and fsid are avaiable, MONs can be created")
	# We have a cluster, help the user not shoot themself in the foot
	file "/etc/ceph/initial-cluster-setup.sh" do
		action :delete
	end
	file "/etc/ceph/chef-crushmap.txt" do
		action :delete
	end
	# Does this monitor already exist?
	if (! File.exists?("/srv/ceph/mon.#{node["hostname"]}/magic") )
		Chef::Log.info("Going to create ceph MON #{node['hostname']}")
		# Setup bootstrap keyring
		bootstrap_key = node['ceph']['mon_bootstrap']
		bootstrap_path = "/tmp/bootstrap-mon-" + randomFileNameSuffix(7)
		%x{if [ ! -f #{bootstrap_path} ]; then touch #{bootstrap_path}; ceph-authtool #{bootstrap_path} --name=mon. --add-key='#{bootstrap_key}'; fi}

		# Create a temporary monmap
		monmap_path = "/tmp/monmap-" + randomFileNameSuffix(7)

		execute "Build empty monmap" do
			command "monmaptool --create #{monmap_path} --fsid #{node['ceph']['fsid']}"
		end

		# Get the list of monitors from Chef to build a monmap
		mon_list = Array.new
		mon_pool = search(:node, "roles:ceph-mon AND chef_environment:#{node.chef_environment}")
		mon_pool.each do |monitor|
			if (node["fqdn"] != monitor["fqdn"])
				mon_list << get_if_ip_for_net('storage',monitor)
			end
		end

		execute "Bootstrap Monitor" do
			command "ceph-mon -i #{node['hostname']} --mkfs --fsid #{node['ceph']['fsid']} --keyring #{bootstrap_path} -m #{mon_list.join(",")}"
		end

		file bootstrap_path do
			action :delete
		end

		file monmap_path do
			action :delete
		end

		execute "Enable Monitor" do
			command "service ceph start mon.#{node['hostname']}"
		end
	else
		Chef::Log.info("No ceph MON needed to be created")
	end
end

cookbook_file "/usr/bin/ceph-cluster-health.pl" do
	source "ceph-cluster-health.pl"
	owner "root"
	group "root"
	mode "0755"
end

cron "ceph-cluster-health" do
	minute "*/5"
	command "/usr/bin/ceph-cluster-health.pl '#{node['ceph']['warning_email']}' '#{node['ceph']['critical_email']}' '#{node['ceph']['cluster_name']}' > /dev/null"
	only_if do File.exist?("/usr/bin/ceph-cluster-health.pl") end
end
