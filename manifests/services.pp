
# == Class: galera_maxscale::services
#
# This Class manages services
#
class galera_maxscale::services {

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
      '/usr/bin/clustercheck', '/root/.my.cnf', '/etc/sysconfig/clustercheck'
    ];
  }

  if $::lsbmajdistrelease == '7' {
    service { 'mariadb':
      ensure   => stopped,
      provider => 'systemd',
      enable   => false;
    }
  }

}
