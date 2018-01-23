
# == Class: galera_maxscale::files
#
# This Class provides files
#
class galera_maxscale::files (
  $backup_compress              = $::galera_maxscale::params::backup_compress,
  $backup_dir                   = $::galera_maxscale::params::backup_dir,
  $backup_retention             = $::galera_maxscale::params::backup_retention,
  $datadir                      = $::galera_maxscale::params::datadir,
  $galera_cluster_name          = $::galera_maxscale::params::galera_cluster_name,
  $innodb_buffer_pool_instances = $::galera_maxscale::params::innodb_buffer_pool_instances,
  $innodb_flush_method          = $::galera_maxscale::params::innodb_flush_method,
  $innodb_io_capacity           = $::galera_maxscale::params::innodb_io_capacity,
  $innodb_log_file_size         = $::galera_maxscale::params::innodb_log_file_size,
  $logdir                       = $::galera_maxscale::params::logdir,
  $max_connections              = $::galera_maxscale::params::max_connections,
  $monitor_password             = $::galera_maxscale::params::monitor_password,
  $monitor_username             = $::galera_maxscale::params::monitor_username,
  $galera_hosts                 = $::galera_maxscale::params::galera_hosts,
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
      content => template("${module_name}/root_my.cnf.erb"),
      notify  => Service['xinetd'];
    '/etc/sysconfig/clustercheck':
      notify  => Service['xinetd'],
      content => template("${module_name}/clustercheck.erb");
    '/usr/bin/clustercheck':
      mode   => '0755',
      source => "puppet:///modules/${module_name}/clustercheck",
      notify => Service['xinetd'];
    '/etc/xinetd.d/galerachk':
      source => "puppet:///modules/${module_name}/galerachk",
      notify => Service['xinetd'];
    '/etc/my.cnf.d/client.cnf':
      source => "puppet:///modules/${module_name}/client.cnf";
    '/etc/my.cnf.d/mysql-clients.cnf':
      source => "puppet:///modules/${module_name}/mysql-clients.cnf";
    '/etc/my.cnf.d/server.cnf':
      mode    => '0640',
      content => template("${module_name}/server.cnf.erb");
  }

}
