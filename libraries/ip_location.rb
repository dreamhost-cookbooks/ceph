#!/usr/bin/env ruby
#
# Copyright 2012-2013, New Dream Network, LLC.
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
#

require "chef/search/query"
require "ipaddr"
require "uri"

def find_ip(network, nodeish=nil)
  nodeish = node unless nodeish
  dest = node["ceph"]["network"][network]
  net = IPAddr.new(dest)
  node["network"]["interfaces"].each do |iface|
    if iface.routes[1].destination == dest
      if net.ipv4?
        return iface.routes[1].src
      else
        iface["addresses"].each do |k,v|
          if v["scope"] == "Global"
            return k
          end
        end
      end
    end
  end
end

def get_quorum_members()
  mon_names = []
  mon_status = %x[ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status]
  raise 'getting quorum members failed' unless $?.exitstatus == 0
  mons = JSON.parse(mon_status)['monmap']['mons']
  mons.each do |k|
    mons_names.push(k['addr'][0..-3])
  end
  return mon_names
end

QUORUM_STATES = ['leader', 'peon']
def have_quorum?()
  mon_status = %x[ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status]
  raise 'getting quorum members failed' unless $?.exitstatus == 0
  state = JSON.parse(mon_status)['state']
  return QUORUM_STATES.include?(state)
end
