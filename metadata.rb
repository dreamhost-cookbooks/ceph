maintainer       "Kyle Bader"
maintainer_email "kyle.bader@dreamhost.com"
license          "Apache 2.0"
description      "Installs/Configures the Ceph distributed filesystem"
#long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))Â
version          "1.0.3"
recipe           "ceph::admin", ""
recipe           "ceph::mds", ""
recipe           "ceph::mon", ""
recipe           "ceph::osd", ""
recipe           "ceph::oss", ""
recipe           "ceph::radosgw", ""
recipe           "ceph::rados-rest", ""

%w{ apache2 apt btrfs parted xfs logrotate supervisord }.each do |cookbook|
	depends cookbook
end

%w{debian ubuntu}.each do |os|
	supports os
end

