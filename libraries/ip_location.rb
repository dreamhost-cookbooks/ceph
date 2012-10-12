#!/usr/bin/env ruby

#
# Shamelessly adapted from Rackspace osops-utils cookbook
# https://github.com/rcbops-cookbooks/osops-utils
#
# Copyright 2012, DreamHost Web Hosting
# Copyright 2012, Rackspace Hosting, Inc.
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

def get_if_for_net(network, nodeish = nil)
  iface, _ = get_if_ip_for_net(network, nodeish)
  return iface
end

def get_if_ip_for_net(network, nodeish = nil)
  nodish = node unless nodeish

   if network == "all"
    return "0.0.0.0"
  end

  if network == "localhost"
    return "127.0.0.1"
  end

  if not (node.has_key?("ceph_networks") and node["ceph_networks"].has_key?(network)) then
    error = "Can't find network #{network}"
    Chef::Log.error(error)
    raise error
  end

  net = IPAddr.new(node["ceph_networks"][network])
  node["network"]["interfaces"].each do |interface|
    interface[1]["addresses"].each do |k,v|
      if v["family"] == "inet6" or v["family"] == "inet" then
        addr=IPAddr.new(k)
        if net.include?(addr) then
          return [interface[0], k]
        end
      end
    end
  end

  error = "Can't find address on network #{network} for node"
  Chef::Log.error(error)
  raise error
end
