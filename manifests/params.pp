# == Class: galera_maxscale::params
#
# Galera Parameters
#
class galera_maxscale::params {

  $backup_compress = false
  $backup_retention = 3
  $backup_dir = '/mnt/galera'
  $daily_hotbackup = undef
  $galera_cluster_name = "${::environment}_galera"
  $galera_pkgs = $::osfamily ? {
    'RedHat' => ['MariaDB-client', 'MariaDB-common', 'MariaDB-compat', 'MariaDB-server'],
    'Debian' => ['mariadb-client', 'mariadb-common', 'mariadb-server'],
  }
  $innodb_buffer_pool_size = '0.7'
  $galera_version = 'latest'
  $http_proxy = undef # example: 'http://proxy.example.net:8080'
  $innodb_buffer_pool_instances = 1
  $innodb_flush_method = 'O_DIRECT'
  $innodb_io_capacity = 200
  $innodb_log_file_size = '512M'
  $logdir = undef
  $lv_size = undef
  $manage_lvm = undef
  $manage_firewall = undef
  $manage_repo = undef
  $max_connections = 1024
  $maxscale_password = undef
  $monitor_password = undef
  $monitor_username = 'monitor'
  $galera_hosts = undef
  $other_pkgs = $::osfamily ? {
    'RedHat' => [
      'percona-xtrabackup-24', 'percona-toolkit', 'python-paramiko',
      'MySQL-python', 'xinetd', 'qpress', 'nc', 'socat'
    ],
    'Debian' => [
      'percona-xtrabackup-24', 'percona-toolkit', 'python-paramiko',
      'python-mysqldb', 'xinetd', 'qpress', 'netcat-openbsd', 'socat'
    ],
  }
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
