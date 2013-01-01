#
# Cookbook Name:: ceph
# Attributes:: default
#
# Copyright 2011, DreamHost.com
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

default["ceph"]["mon_osd_down_out_interval"] = 600
default["ceph"]["debug_mon"] = 20
default["ceph"]["debug_ms"] = 1
default["ceph"]["debug_osd"] = 1
default["ceph"]["debug_filestore"] = 20
default["ceph"]["dmcrypt_osd"] = false
default["ceph"]["networks"]["public"] = "any"
default["ceph"]["apt"]["key_server"] = "pgp.mit.edu"
default["ceph"]["apt"]["ceph_key"] = "7EBFDD5D17ED316D"
default["ceph"]["apt"]["apache2_key"] = "6EAEAE2203C3951A"
default["ceph"]["apt"]["fastcgi_key"] = "6EAEAE2203C3951A"
default["ceph"]["apt"]["ceph_repo"] = "http://ceph.com/debian/"
default["ceph"]["apt"]["apache2_repo"] = "http://deploy.benjamin.dhobjects.net/apache2-precise/combined/"
default["ceph"]["apt"]["fastcgi_repo"] = "http://deploy.benjamin.dhobjects.net/libapache-mod-fastcgi-precise/combined/"
default["ceph"]["mail_host"] = "localhost"
default["ceph"]["warning_email"] = "root"
default["ceph"]["critical_email"] = "root"
default["ceph"]["cluster_name"] = "ceph"
default["ceph"]["config"]["mon"] = {}
default["ceph"]["config"]["osd"] = {}
default["ceph"]["config"]["mds"] = {}
