Description
===========

Installs and configures Ceph, a distributed network storage and filesystem 
designed to provide excellent performance, reliability, and scalability.

Requirements
============

## Platform:

Tested on Debian Squeeze. Should work on any Debian or Ubuntu family
distribution.

## Cookbooks:

The ceph cookbook requires the following cookbooks from Opscode:

https://github.com/opscode/cookbooks

* apache2
* apt
* haproxy
* logrotate

Also required are the following cookbooks from DreamHost.com:

https://git.newdream.net/ops

* btrfs
* parted
* stud

The `apt_repository` LWRP is used to create an entry for the ceph public 
repository.

ATTRIBUTES
==========

## All Ceph Nodes:

All nodes will look to the Ceph version attribute to specify which package
version to install on all nodes in the cluster. This version is pinned in
place with Apt preferences, you can read about how they work here:

http://wiki.debian.org/AptPreferences

Pinning is desireable because it allows the storage administrator to upgrade
the cluster on their own time table. Without pinning the cluster would 
automatically upgrade whenever a new package is pushed to the public Ceph
repository, it is assumed you will be running chef-client in daemon mode.

* node[:ceph][:version]

## Ceph Rados Gateway:

* node[:ceph][:radosgw][:admin_email]
* node[:ceph][:radosgw][:api_fqdn]
* node[:ceph][:radosgw][:listen_addr]
* node[:ceph][:radosgw][:version]

TEMPLATES
=========

USAGE
=====

Ceph cluster design is beyond the scope of this README, please turn to the
public wiki, mailing lists, visit our IRC channel or Ceph Support page:

http://ceph.newdream.net/wiki/
http://ceph.newdream.net/mailing-lists-and-irc/
http://www.cephsupport.com/

## Ceph Monitor:

Simply add `recipe[ceph::mon]` to a run list.

## Ceph Metadata Server:

Simply add `recipe[ceph::mds]` to a run list.

## Ceph OSD:

Simply add `recipe[ceph::osd]` to a run list.

## Ceph Rados Gateway:

Simply add `recipe[ceph::radosgw]` to a run list.

License and Authors
===================

Author:: Kyle Bader (<kyle.bader@dreamhost.com>)
Author:: Carl Perry (<carl.perry@dreamhost.com>)

Copyright:: 2011, DreamHost.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
