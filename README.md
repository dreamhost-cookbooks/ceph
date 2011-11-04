DESCRIPTION
===========

Installs and configures Ceph, a distributed network storage and filesystem 
designed to provide excellent performance, reliability, and scalability.

REQUIREMENTS
============

Platform
--------

Tested as working:
 * Debian Squeeze (6.x)

Cookbooks
---------

The ceph cookbook requires the following cookbooks from Opscode:

https://github.com/opscode/cookbooks

* apache2
* apt
* haproxy

Also required are the following cookbooks New Dream Network (DreamHost.com):

https://github.com/NewDreamNetwork/ceph-cookbooks

* btrfs
* parted
* stud

The `apt_repository` LWRP is used to create an entry for the ceph public 
repository.

ATTRIBUTES
==========

All Ceph Nodes
--------------

All nodes will look to the Ceph version attribute to specify which package
version to install on all nodes in the cluster. This version is pinned in
place with Apt preferences, you can read about how they work here:

http://wiki.debian.org/AptPreferences

Pinning is desireable because it allows the storage administrator to upgrade
the cluster on their own time table. Without pinning the cluster would 
automatically upgrade whenever a new package is pushed to the public Ceph
repository, it is assumed you will be running chef-client in daemon mode.

* node[:ceph][:version]

Ceph Rados Gateway
------------------

* node[:ceph][:radosgw][:api_fqdn]
* node[:ceph][:radosgw][:admin_email]

Ceph Balancer
-------------

*
*

TEMPLATES
=========

USAGE
=====

Ceph cluster design is beyond the scope of this README, please turn to the
public wiki, mailing lists, visit our IRC channel or Ceph Support page:

http://ceph.newdream.net/wiki/
http://ceph.newdream.net/mailing-lists-and-irc/
http://www.cephsupport.com/

This diagram helps visualize recipe inheritence of the ceph cookbook recipes:

 <diagram url>

Ceph Monitor
------------

Ceph monitor nodes should use the ceph::mon recipe. 

Includes:

* ceph::default
* ceph::rados-rest

Ceph Metadata Server
--------------------

Ceph metadata server nodes should use the ceph::mds recipe.

Includes:

* ceph::default

Ceph OSD
--------

Ceph OSD nodes should use the ceph::osd recipe

Includes:

* ceph::default

Ceph Rados Gateway
------------------

Ceph Rados Gateway nodes should use the ceph::radosgw recipe

Includes:

* ceph::rados-rest

Ceph Balancer
-------------

Ceph Balancer nodes should use the ceph::balancer recipe

Includes:

* 

LICENSE AND AUTHORS
===================

* Author: Kyle Bader <kyle.bader@dreamhost.com>

* Copyright 2011, DreamHost Web Hosting

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
