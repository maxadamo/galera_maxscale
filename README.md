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
The subsequent management of the Galera cluster is demanded to the script `galera_wizard.yp`. 
MaxScale Proxy will set up on 2 nodes with Keepalived


## Setup

### Beginning with galera_maxscale

To setup a galera cluster:

```puppet
class { '::galera_maxscale':
  root_password    => $root_password,
  sst_password     => $sst_password,
  monitor_password => $monitor_password,
  galera_hosts     => $galera_hosts,
  trusted_networks => $trusted_networks,
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
```sh
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

If you don't use ipv6, just skip the `ipv6` keys as following:
```yaml
galera_hosts:
  test-galera01.example.net:
    ipv4: '192.168.0.83'
  test-galera02.example.net:
    ipv4: '192.168.0.84'
  test-galera03.example.net:
... and so on ..
```

you need an array of trusted networks/hosts (a list of ipv4/ipv6 networks/hosts allowed to connect to Galera socket):
```yaml
trusted_networks:
  - 192.168.0.1/24
  - 2001:123:4::70/64
  - 192.168.1.44
... and so on ...
```


## Reference



## Limitations

- not fully tested on ipv4 only
- I added `ipv6` to keepalived but it's still not working
- init.pp missing the full list of parameters
- not tested yet on Ubuntu
- initial state transfer is supported only through Percona Xtrabackup. I see no reason to support `mysqldump` and `rsync` since the donor would not be available during the transfer. I'll investigate soon how `mariabackup` works. 
- manage major/minor versions properly


## Development

Feel free to make pull requests and/or open issues on [my GitHub Repository](https://github.com/maxadamo/galera_maxscale) 

## Release Notes/Contributors/Etc. **Optional**
