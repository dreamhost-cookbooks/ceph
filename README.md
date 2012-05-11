Description
===========

Installs and configures Ceph, a distributed network storage and filesystem 
designed to provide excellent performance, reliability, and scalability.

Requirements
============

## Platform:

Tested on Debian Squeeze, Ubuntu Oneiric. Should work on any Debian or Ubuntu family
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

* node[:ceph][:version]

All nodes will look to the Ceph version attribute to specify which package
version to install on all nodes in the cluster. This version is pinned in
place with Apt preferences, you can read about how they work here:

http://wiki.debian.org/AptPreferences

Pinning is desireable because it allows the storage administrator to upgrade
the cluster on their own time table. Without pinning the cluster would 
automatically upgrade whenever a new package is pushed to the public Ceph
repository, it is assumed you will be running chef-client in daemon mode.

## Ceph OSD Nodes:

* node[:ceph][:devices]

An array of devices to be used for OSD creation.  These should be populated
at the node level and contain the following information:

** data_dev : Device which will hold the OSD data volume
** journal_dev : Device which will hold the OSD journal
** osd_id : Can be omitted, will be populated by the osd recipe
** status : on of the following states:
*** create : build a new OSD using these attributes
*** destory : destroy the OSD using these attributes
*** recreate : destroy then create called in sucession
*** anything else : do nothing

* node[:ceph][:filesystem]

Sets the filesystem to be used when creating an OSD mountpoint. Defaults to
xfs (if undefined or an unknown fs used). Possible values: xfs, btrfs, ext4

* node[:ceph][:mkxfsfs_options]
* node[:ceph][:mkbtrfs_options]
* node[:ceph][:mkext4fs_options]

Extra command line options to pass to the appropriate mkfs.  This is useful
for tuning the filesystem metadata size, optimizing for RAID controllers,
etc.  Note that the mkfs command already has a force option and a label
option passed in the recipe.

* node[:ceph][:osd_bootstrap]

This is the CephX key for creating new OSD instances, and is created as
part of the initial cluster creation.  If this key does not exist, or
does not have the correct caps applied to it, then automated OSD
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

Copyright:: 2011, 2012, New Dream Network DBA DreamHost.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
