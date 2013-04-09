#!/usr/bin/env ruby

#
# Shamelessly adapted from Rackspace osops-utils cookbook
# https://github.com/rcbops-cookbooks/osops-utils
#
# Copyright 2012, Rackspace Hosting, Inc.
# Copyright 2012, DreamHost Web Hosting
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

def get_cephnet_ip(network, nodeish = nil)
  nodish = node unless nodeish

  if network == "all"
    return "0.0.0.0"
  end

  if network == "localhost"
    return "127.0.0.1"
  end

  # Check to see if there are networks defined
  ceph = node['ceph']
  if not (ceph.has_key?("networks")) then
    error = "No ceph networks defined, defaulting to 0.0.0.0"
    Chef::Log.warn(error)
    return "0.0.0.0"
  end
  networks = node["ceph"]["networks"]

  # See if the requested network exists
  if not (networks.has_key?(network)) then
    error = "Can't find ceph network #{network}, defaulting to 0.0.0.0"
    Chef::Log.error(error)
    return "0.0.0.0"
  end

  # Get the network list from the attributes.
  # A string is converted to a single item array
  netlist = nil
  if networks[network].kind_of?(Array) then
    netlist = networks[network]
  else
    netlist = Array.new(1, networks[network])
  end

  # Iterate through the networks provided, looking for a match
  netlist.each do |netrequest|
    net = IPAddr.new(netrequest)
    nodeish["network"]["interfaces"].each do |interface|
      interface[1]["addresses"].each do |k,v|
        if v["family"] == "inet6" or v["family"] == "inet" then
          addr=IPAddr.new(k)
          if net.include?(addr) then
            if addr.ipv6? then return "["+addr.to_s+"]" else return addr.to_s end
          end # net include
        end # family check
      end # interface address loop
    end # interface loop
  end # requested network loop

  error = "Can't find address on ceph network #{network} for node"
  Chef::Log.error(error)
  raise error
end
