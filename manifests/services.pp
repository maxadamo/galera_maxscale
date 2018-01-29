
# == Class: galera_maxscale::services
#
# This Class manages services
#
class galera_maxscale::services {

  case $::osfamily {
    'RedHat': {
      if $::lsbmajdistrelease == '7' {
        service { 'mariadb':
          ensure   => stopped,
          provider => 'systemd',
          enable   => false;
        }
      }
    }
    'Debian': {
      service { 'mariadb':
        ensure   => stopped,
        provider => 'systemd',
        enable   => false;
      }
    }
    default: {
      fail("${::operatingsystem} not yet supported")
    }
  }

}
