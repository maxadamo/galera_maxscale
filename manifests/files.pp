
# == Class: galera_maxscale::files
#
# This Class provides files
#
class galera_maxscale::files (
  $backup_compress              = $::galera_maxscale::params::backup_compress,
  $backup_dir                   = $::galera_maxscale::params::backup_dir,
  $backup_retention             = $::galera_maxscale::params::backup_retention,
  $galera_cluster_name          = $::galera_maxscale::params::galera_cluster_name,
  $galera_hosts                 = $::galera_maxscale::params::galera_hosts,
  $galera_pkgs                  = $::galera_maxscale::params::galera_pkgs,
  $innodb_buffer_pool_instances = $::galera_maxscale::params::innodb_buffer_pool_instances,
  $innodb_flush_method          = $::galera_maxscale::params::innodb_flush_method,
  $innodb_io_capacity           = $::galera_maxscale::params::innodb_io_capacity,
  $innodb_log_file_size         = $::galera_maxscale::params::innodb_log_file_size,
  $logdir                       = $::galera_maxscale::params::logdir,
  $max_connections              = $::galera_maxscale::params::max_connections,
  $monitor_password             = $::galera_maxscale::params::monitor_password,
  $monitor_username             = $::galera_maxscale::params::monitor_username,
  $query_cache                  = $::galera_maxscale::params::query_cache,
  $root_password                = $::galera_maxscale::params::root_password,
  $sst_password                 = $::galera_maxscale::params::sst_password,
  $thread_cache_size            = $::galera_maxscale::params::thread_cache_size,
  $tmpdir                       = $::galera_maxscale::params::tmpdir,
  $slow_query_time              = $::galera_maxscale::params::slow_query_time,
  ) inherits galera_maxscale::params {

  unless defined( File['/root/bin'] ) {
    file { '/root/bin':
      ensure => directory,
      mode   => '0755';
    }
  }

  $config_dir = $::osfamily ? {
    'RedHat' => '/etc/sysconfig',
    'Debian' => '/etc/default',
  }

  file {
    default:
      ensure  => file,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => FIle['/root/bin'];
    '/usr/bin/galera_wizard.py':
      mode   => '0755',
      source => "puppet:///modules/${module_name}/galera_wizard.py";
    '/root/galera_params.py':
      content => template("${module_name}/galera_params.py.erb"),
      notify  => Service['xinetd'];
    '/root/bin/hotbackup.sh':
      mode    => '0755',
      content => template("${module_name}/hotbackup.sh.erb"),
      require => File['/root/bin'],
      notify  => Service['xinetd'];
    '/root/.my.cnf':
      mode    => '0660',
      notify  => Xinetd::Service['galerachk'],
      require => Package[$galera_pkgs],
      content => template("${module_name}/root_my.cnf.erb");
    "${config_dir}/clustercheck":
      notify  => Xinetd::Service['galerachk'],
      content => template("${module_name}/clustercheck_config.erb");
    '/usr/bin/clustercheck':
      mode    => '0755',
      notify  => Xinetd::Service['galerachk'],
      content => template("${module_name}/clustercheck_script.erb");
  }

  case $::osfamily {
    'RedHat': {
      file {
        default:
          ensure  => file,
          mode    => '0644',
          owner   => 'root',
          group   => 'root',
          require => Package[$galera_pkgs];
        '/etc/my.cnf.d/client.cnf':
          source  => "puppet:///modules/${module_name}/client.cnf",
          require => Package[$galera_pkgs];
        '/etc/my.cnf.d/mysql-clients.cnf':
          source  => "puppet:///modules/${module_name}/mysql-clients.cnf.${::osfamily}",
          require => Package[$galera_pkgs];
        '/etc/my.cnf.d/server.cnf':
          mode    => '0640',
          content => template("${module_name}/server.cnf.erb"),
          require => Package[$galera_pkgs];
      }
    }
    'Debian': {
      file {
        default:
          ensure => file,
          mode   => '0644',
          owner  => 'root',
          group  => 'root';
        '/etc/mysql/my.cnf':
          require => Package[$galera_pkgs],
          content => template("${module_name}/server.cnf.erb");
        '/etc/mysql/mariadb.conf.d/mysql-clients.cnf':
          require => Package[$galera_pkgs],
          source  => "puppet:///modules/${module_name}/mysql-clients.cnf.${::osfamily}";
        '/etc/rc.d/mysql':
          mode   => '0755',
          source => "puppet:///modules/${module_name}/mysql";
        '/etc/init.d/mysql':
          mode   => '0755',
          source => "puppet:///modules/${module_name}/mysql";
      }
    }
    default: {
      fail("${::operatingsystem} not yet supported")
    }
  }

}
