## Preamble

This module will setup and bootstrap Galera cluster.  The subsequent management of the cluster is done through the script `galera_wizard.yp`. 
MaxScale is setup with Keepalived. 


## Compatibility

- it's tested against CentOS 7 and MariaDB 10.2
- it makes use of extrabackup-v2 for the initial State Transfer (I still need to test the new `mariabackup`, but with the other tools, the donor node is unavailable during the initial transfer).

## ToDo

- add the ability to change root password
- test it on Ubuntu LTS
- test better ipv4 only

## Usage

The module will fail with an even number of nodes, and with a number of nodes lower than 3.

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

If you don't use ipv6, just skip the ipv6 key as following:
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

To setup a galera cluster:

```puppet
class { 'galera':
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
class { 'galera::maxscale::maxscale':
  trusted_networks => $trusted_networks,
  maxscale_hosts   => $maxscale_hosts,
  maxscale_vip     => $maxscale_vip,
  galera_hosts     => $galera_hosts;
}
```

Once you have run puppet, you can connect to the nodes and you the tool:
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

Author: Massimiliano Adamo <maxadamo@gmail.com>
```
