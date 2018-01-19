
# == Class: galera::files
#
# This Class provides files
#
class galera::files (
  $backup_compress              = $::galera::params::backup_compress,
  $backup_retention             = $::galera::params::backup_retention,
  $datadir                      = $::galera::params::datadir,
  $galera_cluster_name          = $::galera::params::galera_cluster_name,
  $innodb_buffer_pool_instances = $::galera::params::innodb_buffer_pool_instances,
  $innodb_flush_method          = $::galera::params::innodb_flush_method,
  $innodb_io_capacity           = $::galera::params::innodb_io_capacity,
  $innodb_log_file_size         = $::galera::params::innodb_log_file_size,
  $logdir                       = $::galera::params::logdir,
  $max_connections              = $::galera::params::max_connections,
  $monitor_password             = $::galera::params::monitor_password,
  $monitor_username             = $::galera::params::monitor_username,
  $galera_hosts                 = $::galera::params::galera_hosts,
  $query_cache                  = $::galera::params::query_cache,
  $root_password                = $::galera::params::root_password,
  $sst_password                 = $::galera::params::sst_password,
  $thread_cache_size            = $::galera::params::thread_cache_size,
  $tmpdir                       = $::galera::params::tmpdir,
  $slow_query_time              = $::galera::params::slow_query_time,
  ) inherits galera {

  if ! defined( File['/root/bin'] ) {
    file { '/root/bin':
      ensure => directory,
      mode   => '0755';
    }
  }

  file {
    default:
      ensure => file,
      mode   => '0644',
      owner  => 'root',
      group  => 'root';
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
      content => template("${module_name}/my.cnf.erb"),
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
      content => template("${module_name}/client.cnf.erb");
    '/etc/my.cnf.d/mysql-clients.cnf':
      content => template("${module_name}/mysql-clients.cnf.erb");
    '/etc/my.cnf.d/server.cnf':
      mode    => '0640',
      content => template("${module_name}/server.cnf.erb");
  }

}
