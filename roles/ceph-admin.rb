name "ceph-admin"
description "All Ceph Admin servers"
run_list(
        "recipe[ceph::default]",
        "recipe[ceph::config]",
	"recipe[ceph::admin]"
)
