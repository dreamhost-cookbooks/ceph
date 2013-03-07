#
# Cookbook Name:: ceph
# Attributes:: radosgw
#
# Copyright 2011-2013, New Dream Network, LLC.
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
default["ceph"]["radosgw"]["admin-email"] = "admin@example.com"
default["ceph"]["radosgw"]["api_fqdn"] = "127.0.0.1"
default["ceph"]["radosgw"]["listen_addr"] = "127.0.0.1"
default["ceph"]["radosgw"]["version"] = "2.2.16-6+squeeze1-3-g80f8a77"
