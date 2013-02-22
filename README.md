Description
===========

Installs and configures Ceph, a distributed object store and filesystem
designed to provide excellent performance, reliability, and scalability.

Requirements
============

## Platform:

Ubuntu Precise (12.04)

## Cookbooks:

The Ceph cookbook requires the following cookbooks from Opscode:

https://github.com/opscode-cookbooks

* apache2
* apt
* logrotate

The `apt_repository` LWRP is used to create an entries for the ceph public 
repositories.

ATTRIBUTES
==========

## All Ceph Nodes:

* node[:ceph][:repo_uri]
* node[:ceph][:version]

All nodes will look to the Ceph version attribute to specify which package
version to install on all nodes in the cluster. This version is pinned in
place with Apt preferences, you can read about how they work here:

http://wiki.debian.org/AptPreferences

## Ceph OSD Nodes

* node[:ceph][:devices]

An array of devices to be used for OSD creation. These should be populated at
the node level and contain the following information:

* node[:ceph][:devices][:osd\_device]

Device which will hold the data and journal volume for an OSD.

* node[:ceph][:devices][:osd\_device][:status]

The natural state of an OSD device is hold, in this state no action will be
taken. Each device can optionally be set to any of three states that will cause
actions to be triggered the next time their host node converges:

* 'create' - Bootstrap and activate this device as a Ceph OSD
* 'destory' - Deactivate the OSD within Ceph and zero fill the device
* 'recreate' - Destroy then create called in succession

* node[:ceph][:osd_bootstrap]

This is the CephX key that is used for creating new OSD instances and is
created as part of the initial cluster creation.  If this key does not exist,
or does not have the correct capabilities applied to it, then automated OSD
management will not function.

## Ceph MON Nodes

* node[:ceph][:mon_bootstrap]

This is the CephX key for creating new MON nodes.  This too is created
as part of the initial cluster creation.  If this key does not exist
then automated MON mangement will not function.

* node[:ceph][:fsid]

This is the unique Ceph filesystem ID for the cluster.  This ensures
that multiple clusters on the same network(s) do not interact.  If
this does not exist then automate MON mangement will not function.

## Ceph Rados Gateway

* node[:ceph][:apache2_repo_uri]
* node[:ceph][:fastcgi_repo_uri]
* node[:ceph][:radosgw][:admin\_email]
* node[:ceph][:radosgw][:api\_fqdn]
* node[:ceph][:radosgw][:listen\_addr]
* node[:ceph][:radosgw][:version]
* node[:ceph][:apache][:version]
* node[:ceph][:fastcgi][:version]

USAGE
=====

Ceph cluster design is beyond the scope of this README, please turn to the
public wiki, mailing lists, visit our IRC channel or Ceph Support page:

http://ceph.newdream.net/wiki/
http://ceph.newdream.net/mailing-lists-and-irc/
http://www.cephsupport.com/

## Ceph Monitor

Simply add `recipe[ceph::mon]` to a run list.

## Ceph Metadata Server

Simply add `recipe[ceph::mds]` to a run list.

## Ceph OSD

Simply add `recipe[ceph::osd]` to a run list.

## Ceph Rados Gateway

Simply add `recipe[ceph::radosgw]` to a run list.

License and Authors
===================

Author:: Kyle Bader (<kyle.bader@dreamhost.com>)
Author:: Carl Perry (<carl.perry@dreamhost.com>)

Copyright:: 2011-2013 New Dream Network, LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
