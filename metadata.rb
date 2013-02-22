maintainer       "Kyle Bader"
maintainer_email "kyle.bader@dreamhost.com"
license          "Apache 2.0"
description      "Installs/Configures the Ceph distributed filesystem"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"
recipe           "ceph::admin", ""
recipe           "ceph::mds", ""
recipe           "ceph::mon", ""
recipe           "ceph::osd", ""
recipe           "ceph::oss", ""
recipe           "ceph::radosgw", ""
recipe           "ceph::rados-rest", ""

%w{ apache2 apt logrotate }.each do |cookbook|
  depends cookbook
end

#supports ubuntu

