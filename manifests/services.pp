
# == Class: galera_maxscale::services
#
# This Class manages services
#
class galera_maxscale::services {

  service { 'xinetd':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['xinetd'];
  }

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
      # code
    }
    default: {
      # code
    }
  }

}
