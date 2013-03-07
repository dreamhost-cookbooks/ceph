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
* ntp
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

* node[:ceph][:fsid]

This is the unique Ceph filesystem ID for the cluster. This ensures that
multiple clusters on the same network(s) do not interact.  If this does
not exist then automated MON mangement will not function. You can generate
a fsid with uuidgen from the Ubuntu package "uuid-runtime":

$ uuidgen
cbc61c76-2d49-4589-b4f3-a0cef9dd19d7

* node[:ceph][:rack]
* node[:ceph][:row]

These attributes specify which rack and row the nodes in the cluster are located
in. This is used to configure CRUSH, the placement algorithm used by Ceph to
achieve statisically even distribution of data.

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
* 'zapdisk' - Zap disk and recreate a Ceph OSD

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

Cluster Design
--------------

Ceph cluster design is beyond the scope of this README. You should familiarize
yourself with the documentation at the Ceph website:

http://ceph.com/docs/master/

If you require support you can try reach out to the community by sending a
message mailing list or joining the IRC channel:

http://ceph.com/resources/mailing-list-irc/

Professional services for Ceph storage systems are availible through Inktank,
the primary sponsor of Ceph development.

http://www.inktank.com/

Cluster Setup
-------------

The first thing you will do to stand up a new Ceph cluster is configure the Ceph
monitors. You will need to generate a cluster uuid (also refered to as a fsid),
for details consult the attributes section for recipe[ceph::mon].

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

Copyright:: 2011-2013, New Dream Network, LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
