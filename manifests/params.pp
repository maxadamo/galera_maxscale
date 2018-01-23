# == Class: galera_maxscale::params
#
# Galera Parameters
#
class galera_maxscale::params {

  $backup_compress = false
  $backup_retention = 3
  $backup_dir = '/mnt/galera'
  $daily_hotbackup = undef
  $datadir = '/var/lib/mysql'
  $galera_cluster_name = "${::environment}_galera"
  $galera_pkgs = ['MariaDB-client', 'MariaDB-common', 'MariaDB-compat', 'MariaDB-server']
  $innodb_buffer_pool_size = '0.7'
  $galera_version = 'latest'
  $innodb_buffer_pool_instances = 1
  $innodb_flush_method = 'O_DIRECT'
  $innodb_io_capacity = 200
  $innodb_log_file_size = '512M'
  $logdir = undef
  $lv_size = undef
  $manage_lvm = undef
  $manage_firewall = true
  $manage_repo = true
  $max_connections = 1024
  $maxscale_password = undef
  $monitor_password = undef
  $monitor_username = 'monitor'
  $galera_hosts = undef
  $other_pkgs = [
    'percona-xtrabackup-24', 'percona-toolkit', 'python-paramiko',
    'MySQL-python', 'xinetd', 'qpress', 'nc', 'socat'
  ]
  $root_password = undef
  $sst_password = undef
  $thread_cache_size = 16
  $tmpdir = undef
  $trusted_networks = undef
  $version = 'latest'
  $vg_name = undef

  # MaxScale configuration
  $maxscale_hosts = undef
  $maxscale_vip = undef

}
