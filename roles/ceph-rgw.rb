name "ceph-rgw"
description "All Ceph metadata servers"
run_list(
        "recipe[ntp]",
        "recipe[ceph::default]",
        "recipe[ceph::config]",
	"recipe[ceph::radosgw]"
)
default_attributes(
        "service" => "ntp",
        "ntp" => {
                "servers" => ["clock1.dreamhost.com", "clock2.dreamhost.com", "clock3.dreamhost.com"]
        },
        "service" => "timezone",
        "timezone" => "UTC"
)
