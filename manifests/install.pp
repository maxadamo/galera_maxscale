# == Class: galera_maxscale::install
#
# This Class installs all the packages
#
class galera_maxscale::install (
  $other_pkgs            = $::galera_maxscale::params::other_pkgs,
  $percona_major_version = $::galera_maxscale::params::percona_major_version,
  ) inherits galera_maxscale::params {

  $config_dir = $::osfamily ? {
    'RedHat' => '/etc/sysconfig',
    'Debian' => '/etc/default',
  }

  xinetd::service { 'galerachk':
    server         => '/usr/bin/clustercheck',
    port           => '9200',
    user           => 'root',
    group          => 'root',
    groups         => 'yes',
    flags          => 'REUSE',
    log_on_success => '',
    log_on_failure => 'HOST',
    require        => File[
      '/usr/bin/clustercheck', '/root/.my.cnf', "${config_dir}/clustercheck"
    ];
  }
  case $::operatingsystem {
    'RedHat', 'CentOS': {
      package {
        $other_pkgs:
          ensure => latest;
        "Percona-Server-shared-compat-${percona_major_version}":
          ensure => installed,
          before => Package["Percona-XtraDB-Cluster-full-${percona_major_version}"];
        "Percona-XtraDB-Cluster-full-${percona_major_version}":
          ensure => installed;
      }
    }
    'Ubuntu': {
      package {
        default:
          require => Exec['apt_update'];
        $other_pkgs:
          ensure => latest;
      }
    }
    default: {
      fail("${::operatingsystem} not yet supported")
    }
  }

}
