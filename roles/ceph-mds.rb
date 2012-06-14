name "ceph-mds"
description "All Ceph metadata servers"
run_list(
	"role[dho]",
	"recipe[ceph::mds]"
)
