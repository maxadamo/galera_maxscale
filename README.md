# galera_maxscale

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with galera_maxscale](#setup)
    * [Beginning with galera_maxscale](#beginning-with-galera_maxscale)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module sets up and bootstrap Galera cluster and MaxScale Proxy.
The status of the cluster is checked at run time through the facter `galera_status` and puppet will attempt to re-join the node in case of disconnection.
If puppet fails to recover a node you can use the script `galera_wizard.yp` provided with this module.
MaxScale Proxy will be set up on 2 nodes (no more, no less) with Keepalived.

Therefore:
    - if you want only the Galera cluster you need _at least_ 3 servers and 4 ipv4 (and optionally 4 ipv6)
    - if you want the full stack you need _at least_ 5 servers and 6 IPv4 (and optionally 6 IPv6)

Initial State Snapshot Transfer is supported only through Percona XtraBackup (on average DBs I see no reason to use `mysqldump` and `rsync` since the donor would be unavailable during the transfer: see [Galera Documentation](http://galeracluster.com/documentation-webpages/sst.html)).
The backup provided with this modules is indeed poor, but it can be considered as an example if you really want to use Percona XtraBackup.

**When bootstrapping, avoid running puppet on all the nodes at same time.**

**stay tuned:** since the module is at an early stage, for the time being it will receive frequent updates (at same time, the module should be considered as **Beta**).

Read at (actual) **limitations** in the paragraph below.


## Setup

### Beginning with galera_maxscale

To setup Galera:

```puppet
class { '::galera_maxscale':
  root_password    => $root_password,
  sst_password     => $sst_password,
  monitor_password => $monitor_password,
  maxscale_hosts   => $maxscale_hosts,
  maxscale_vip     => $maxscale_hosts,
  galera_hosts     => $galera_hosts,
  trusted_networks => $trusted_networks,
  manage_lvm       => true,
  vg_name          => 'rootvg',
  lv_size          => $lv_size;
}
```

To setup MaxScale:
```puppet
class { '::galera_maxscale::maxscale::maxscale':
  trusted_networks => $trusted_networks,
  maxscale_hosts   => $maxscale_hosts,
  maxscale_vip     => $maxscale_vip,
  galera_hosts     => $galera_hosts;
}
```

Once you have run puppet on every node, you can manage or check the cluster using the script:
```
[root@test-galera01 ~]# galera_wizard.py -h
usage: galera_wizard.py [-h] [-cg] [-dr] [-je] [-be] [-jn] [-bn]

Use this script to bootstrap, join nodes within a Galera Cluster
----------------------------------------------------------------
  Avoid joining more than one node at once!

optional arguments:
  -h, --help                 show this help message and exit
  -cg, --check-galera        check if all nodes are healthy
  -dr, --dry-run             show SQL statements to run on this cluster
  -je, --join-existing       join existing Cluster
  -be, --bootstrap-existing  bootstrap existing Cluster
  -jn, --join-new            join existing Cluster
  -bn, --bootstrap-new       bootstrap new Cluster
  -f, --force                force bootstrap new or join new Cluster

Author: Massimiliano Adamo <maxadamo@gmail.com>
```

## Usage

The module will fail on Galera with an even number of nodes and with a number of nodes lower than 3.

To setup a Galera Cluster (and optionally a MaxScale cluster with Keepalived) we need a hash. If you use hiera it will be like this:

```yaml
galera_hosts:
  test-galera01.example.net:
    ipv4: '192.168.0.83'
    ipv6: '2001:123:4::6b'
  test-galera02.example.net:
    ipv4: '192.168.0.84'
    ipv6: '2001:123:4::6c'
  test-galera03.example.net:
    ipv4: '192.168.0.85'
    ipv6: '2001:123:4::6d'
maxscale_hosts:
  test-maxscale01.example.net:
    ipv4: '192.168.0.86'
    ipv6: '2001:123:4::6e'
  test-maxscale02.example.net:
    ipv4: '192.168.0.87'
    ipv6: '2001:123:4::6f'
maxscale_vip:
  test-maxscale.example.net:
    ipv4: '192.168.0.88'
    ipv4_subnet: '22'
    ipv6: '2001:123:4::70'
```

If you do not use ipv6, just skip the `ipv6` keys as following:
```yaml
galera_hosts:
  test-galera01.example.net:
    ipv4: '192.168.0.83'
  test-galera02.example.net:
    ipv4: '192.168.0.84'
  test-galera03.example.net:
... and so on ..
```

you need an array of trusted networks/hosts (a list of ipv4/ipv6 networks/hosts allowed to connect to MySQL socket):
```yaml
trusted_networks:
  - 192.168.0.1/24
  - 2001:123:4::70/64
  - 192.168.1.44
... and so on ...
```

## Reference



## Limitations

- not tested yet on ipv4 only
- handle major/minor versions properly


## Development

Feel free to make pull requests and/or open issues on [my GitHub Repository](https://github.com/maxadamo/galera_maxscale)

## Release Notes/Contributors/Etc. **Optional**
