name "ceph-client"
description "All Ceph generic client nodes"
run_list(
        "recipr[ceph::default]",
        "recipe[ceph::config]",
	"recipe[ceph::client]"
)
