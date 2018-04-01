# Module Deprecation Notice

Please consider using the new module [galera_proxysql](https://forge.puppet.com/maxadamo/galera_proxysql).

The new module makes use of Percona instead of MariaDB.

I came to this decision after having observed the followings:

1. percona repository is still needed to use percona tools
1. the preferred method for SST is Percona-extrabackup
1. maxscale started throwing coredumps
1. a bug in the extrabackup-v2 script appeared all of a sudden and I had to roll-back to extrabackup
1. With Percona only 1 repository is needed. With MariaDB 3 repositories were needed (1 for Percona, 1 for MariaDB, 1 for MaxScale).
