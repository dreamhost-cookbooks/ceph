name "ceph-osd"
description "All Ceph object storage device servers"
run_list(
        "recipe[ntp]",
	"recipe[ceph::default]",
	"recipe[ceph::osd]",
        "recipe[ceph::config]"
)
default_attributes(
        "service" => "ntp",
        "ntp" => {
                "servers" => ["clock1.dreamhost.com", "clock2.dreamhost.com", "clock3.dreamhost.com"]
        },
        "service" => "timezone",
        "timezone" => "UTC",
	"sysctl" => {
		"vm" => {
			"dirty_background_bytes" => 1000000
		}
	}
)
