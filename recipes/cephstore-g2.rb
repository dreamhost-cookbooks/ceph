#
# Cookbook Name:: cephstore
# Recipe:: default
#
# Copyright 2013, New Dream Network, LLC.
#
# All rights reserved - Do Not Redistribute
#

node.normal['ceph']['osd-devices'] = [
  {
    'device' => '/dev/sdb',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdc',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdd',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sde',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdf',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdg',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdh',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdi',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdj',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdk',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdl',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  },
  {
    'device' => '/dev/sdm',
    'filesystem' => 'xfs',
    'encrypted' => true,
    'status' => 'zapdisk'
  }
]
