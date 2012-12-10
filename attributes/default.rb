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
default["ceph"]["apt"]["key"] = "7EBFDD5D17ED316D"
default["ceph"]["apt"]["repo"] = "http://ceph.com/debian/"
