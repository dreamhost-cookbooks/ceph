#
# Cookbook Name:: cephstore
# Recipe:: default
#
# Copyright 2013, New Dream Network, LLC.
#
# All rights reserved - Do Not Redistribute
#

node.normal['ceph']['osd-devices'][0]['device'] = '/dev/sdb'
node.normal['ceph']['osd-devices'][0]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][0]['encrypted'] = true 
node.normal['ceph']['osd-devices'][0]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][1]['device'] = '/dev/sdc'
node.normal['ceph']['osd-devices'][1]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][1]['encrypted'] = true 
node.normal['ceph']['osd-devices'][1]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][2]['device'] = '/dev/sdd'
node.normal['ceph']['osd-devices'][2]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][2]['encrypted'] = true 
node.normal['ceph']['osd-devices'][2]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][3]['device'] = '/dev/sde'
node.normal['ceph']['osd-devices'][3]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][3]['encrypted'] = true 
node.normal['ceph']['osd-devices'][3]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][4]['device'] = '/dev/sdf'
node.normal['ceph']['osd-devices'][4]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][4]['encrypted'] = true 
node.normal['ceph']['osd-devices'][4]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][5]['device'] = '/dev/sdg'
node.normal['ceph']['osd-devices'][5]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][5]['encrypted'] = true 
node.normal['ceph']['osd-devices'][5]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][6]['device'] = '/dev/sdh'
node.normal['ceph']['osd-devices'][6]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][6]['encrypted'] = true 
node.normal['ceph']['osd-devices'][6]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][7]['device'] = '/dev/sdi'
node.normal['ceph']['osd-devices'][7]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][7]['encrypted'] = true 
node.normal['ceph']['osd-devices'][7]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][8]['device'] = '/dev/sdj'
node.normal['ceph']['osd-devices'][8]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][8]['encrypted'] = true 
node.normal['ceph']['osd-devices'][8]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][9]['device'] = '/dev/sdk'
node.normal['ceph']['osd-devices'][9]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][9]['encrypted'] = true 
node.normal['ceph']['osd-devices'][9]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][10]['device'] = '/dev/sdl'
node.normal['ceph']['osd-devices'][10]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][10]['encrypted'] = true 
node.normal['ceph']['osd-devices'][10]['status'] = 'zapdisk'

node.normal['ceph']['osd-devices'][11]['device'] = '/dev/sdm'
node.normal['ceph']['osd-devices'][11]['filesystem'] = 'xfs'
node.normal['ceph']['osd-devices'][11]['encrypted'] = true 
node.normal['ceph']['osd-devices'][11]['status'] = 'zapdisk'

