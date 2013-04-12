maintainer       "Kyle Bader"
maintainer_email "kyle.bader@dreamhost.com"
license          "Apache 2.0"
description      "Installs/Configures the Ceph distributed filesystem"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.66"
recipe           "ceph::admin", "Ceph admin keyring"
recipe           "ceph::mds", "Ceph metadata server"
recipe           "ceph::mon", "Ceph monitor"
recipe           "ceph::osd", "Ceph object storage device"
recipe           "ceph::oss", "Ceph object sync"
recipe           "ceph::radosgw", "Ceph RESTful RADOS gateway"
recipe           "ceph::rados", "Ceph RADOS"

%w{ apache2 apt logrotate ntp }.each do |cookbook|
  depends cookbook
end

#supports ubuntu

