# == Class: galera::install
#
# This Class installs all the packages
#
class galera::install (
  $galera_pkgs = $::galera::galera_pkgs,
  $other_pkgs  = $::galera::other_pkgs
  ) inherits galera::params {

  package {
    $other_pkgs:
      ensure => latest;
    'MariaDB-shared':
      ensure  => $galera::version;
    $galera_pkgs:
      ensure  => $galera::version,
      require => Package['MariaDB-shared'];
    'galera':
      ensure  => $galera::galera_version;
  }

}
