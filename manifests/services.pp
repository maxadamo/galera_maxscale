
# == Class: galera_maxscale::services
#
# This Class manages services
#
class galera_maxscale::services {

  if $::lsbmajdistrelease == '7' {
    service { 'mariadb':
      ensure   => stopped,
      provider => 'systemd',
      enable   => false;
    }
  }

}
