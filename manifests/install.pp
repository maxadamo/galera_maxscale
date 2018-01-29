# == Class: galera_maxscale::install
#
# This Class installs all the packages
#
class galera_maxscale::install (
  $galera_pkgs     = $::galera_maxscale::galera_pkgs,
  $other_pkgs      = $::galera_maxscale::other_pkgs,
  $mariadb_version = $::galera_maxscale::mariadb_version,
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
        'MariaDB-shared':
          ensure  => $mariadb_version;
        $galera_pkgs:
          ensure  => $mariadb_version,
          require => Package['MariaDB-shared'];
        'galera':
          ensure  => $galera_maxscale::galera_version;
      }
    }
    'Ubuntu': {
      package {
        default:
          require => Exec['apt_update'];
        $other_pkgs:
          ensure => latest;
        $galera_pkgs:
          ensure  => $mariadb_version;
        'galera-3':
          ensure  => $galera_maxscale::galera_version;
      }
    }
    default: {
      fail("${::operatingsystem} not yet supported")
    }
  }

}
