name "ceph-oss"
description "All Ceph object sync servers"
run_list(
	"recipe[ceph::oss]"
)
