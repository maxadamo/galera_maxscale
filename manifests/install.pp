# == Class: galera_maxscale::install
#
# This Class installs all the packages
#
class galera_maxscale::install (
  $galera_pkgs = $::galera_maxscale::galera_pkgs,
  $other_pkgs  = $::galera_maxscale::other_pkgs
  ) inherits galera_maxscale::params {

  case $::operatingsystem {
    'RedHat', 'CentOS': {
      package {
        $other_pkgs:
          ensure => latest;
        'MariaDB-shared':
          ensure  => $galera_maxscale::version;
        $galera_pkgs:
          ensure  => $galera_maxscale::version,
          require => Package['MariaDB-shared'];
        'galera':
          ensure  => $galera_maxscale::galera_version;
      }
    }
    'Ubuntu': {
      package {
        $other_pkgs:
          ensure => latest;
        $galera_pkgs:
          ensure  => $galera_maxscale::version;
        'galera':
          ensure  => $galera_maxscale::galera_version;
      }
    }
    'default': {
      fail("${::operatingsystem} not yet supported")
    }
  }


}
