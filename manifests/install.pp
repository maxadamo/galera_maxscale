# == Class: galera_maxscale::install
#
# This Class installs all the packages
#
class galera_maxscale::install (
  $galera_pkgs     = $::galera_maxscale::galera_pkgs,
  $other_pkgs      = $::galera_maxscale::other_pkgs,
  $mariadb_version = $::galera_maxscale::mariadb_version,
  ) inherits galera_maxscale::params {

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
