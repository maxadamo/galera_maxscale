
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

}
