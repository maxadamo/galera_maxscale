
# == Class: galera::join
#
# This Class manages services
#
class galera::join (
  $monitor_password  = $::galera::params::monitor_password,
  $root_password     = $::galera::params::root_password,
  $sst_password      = $::galera::params::sst_password,
  $maxscale_password = $::galera::params::maxscale_password,
  $galera_hosts      = $::galera::params::galera_hosts,
  $maxscale_hosts    = $::galera::params::maxscale_hosts,
  $maxscale_vip      = $::galera::params::maxscale_vip,
  ) inherits galera::params {

  $joined_file = '/root/.JOINED'

  exec { 'bootstrap_or_join':
    command => 'galera_wizard.py -bn -f || galera_wizard.py -jn -f',
    path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
    creates => $joined_file,
    returns => [0,1],
    require => [
      File['/usr/bin/galera_wizard.py', '/root/galera_params.py', '/root/.my.cnf'],
      Package['galera']
    ];
  }

  $joined_exists = inline_template('<% if File.exist?(@joined_file) -%>true<% end -%>')

  if ($joined_exists) {
    galera::create_user {
      'sstuser':
        galera_hosts   => $galera_hosts,
        maxscale_hosts => $maxscale_hosts,
        maxscale_vip   => $maxscale_vip,
        require        => Exec['bootstrap_or_join'],
        dbpass         => $sst_password;
      'monitor':
        galera_hosts   => $galera_hosts,
        maxscale_hosts => $maxscale_hosts,
        maxscale_vip   => $maxscale_vip,
        require        => Exec['bootstrap_or_join'],
        dbpass         => $monitor_password;
    }
    if $maxscale_password {
      galera::create_user { 'maxscale':
        galera_hosts   => $galera_hosts,
        maxscale_hosts => $maxscale_hosts,
        maxscale_vip   => $maxscale_vip,
        require        => Exec['bootstrap_or_join'],
        dbpass         => $maxscale_password;
      }
    }
  }

}
