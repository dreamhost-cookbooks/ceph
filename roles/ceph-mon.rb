name "ceph-mon"
description "All Ceph monitor servers"
run_list(
        "recipe[ntp]",
        "recipe[ceph::config]",
        "recipe[ceph::admin]",
	"recipe[ceph::mon]"
)
default_attributes(
        "service" => "ntp",
        "ntp" => {
                "servers" => ["clock1.dreamhost.com", "clock2.dreamhost.com", "clock3.dreamhost.com"]
        },
        "service" => "timezone",
        "timezone" => "UTC"
)
