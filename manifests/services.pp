
# == Class: galera::services
#
# This Class manages services
#
class galera::services {

  service { 'xinetd':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['xinetd'];
  }

}
