# == Class: galera_maxscale::params
#
# Galera Parameters
#
class galera_maxscale::params {

  # galera parameters
  $backup_compress = false
  $backup_retention = 3
  $backup_dir = '/mnt/galera'
  $daily_hotbackup = undef
  $galera_cluster_name = "${::environment}_galera"
  $galera_hosts = undef
  $innodb_buffer_pool_size = '0.7'
  $innodb_buffer_pool_instances = 1
  $innodb_flush_method = 'O_DIRECT'
  $innodb_io_capacity = 200
  $innodb_log_file_size = '512M'
  $logdir = undef
  $lv_size = undef
  $percona_major_version = '57'
  $manage_lvm = undef
  $max_connections = 1024
  $monitor_password = undef
  $monitor_username = 'monitor'
  $other_pkgs = [
    'percona-xtrabackup-24', 'percona-toolkit', 'python-paramiko',
    'MySQL-python', 'qpress', 'nc', 'socat'
  ]
  $root_password = undef
  $sst_password = undef
  $thread_cache_size = 16
  $tmpdir = undef
  $trusted_networks = undef
  $vg_name = undef

  # proxysql configuration
  $proxysql_version  = 'latest'
  $proxysql_vip = undef
  $proxysql_password = undef
  $proxysql_major_version = '2.1.13'

  # proxysql Keepalive configuration
  $network_interface = 'eth0'

  # Common Parameters
  $http_proxy = undef # example: 'http://proxy.example.net:8080'
  $manage_firewall = true
  $manage_repo = true
  $proxysql_hosts = undef


}
