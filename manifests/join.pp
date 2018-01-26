
# == Class: galera_maxscale::join
#
# This Class manages services
#
class galera_maxscale::join (
  $monitor_password  = $::galera_maxscale::params::monitor_password,
  $root_password     = $::galera_maxscale::params::root_password,
  $sst_password      = $::galera_maxscale::params::sst_password,
  $maxscale_password = $::galera_maxscale::params::maxscale_password,
  $galera_hosts      = $::galera_maxscale::params::galera_hosts,
  $maxscale_hosts    = $::galera_maxscale::params::maxscale_hosts,
  $maxscale_vip      = $::galera_maxscale::params::maxscale_vip,
  $manage_lvm        = $::galera_maxscale::params::manage_lvm,
  ) inherits galera_maxscale::params {

  $joined_file = '/var/lib/mysql/gvwstate.dat'

  $galera_package = $::osfamily ? {
    'RedHat' => 'galera',
    'Debian' => 'galera-3',
  }

  $file_list = $::osfamily ? {
    'RedHat' => [
      '/usr/bin/galera_wizard.py', '/root/galera_params.py',
      '/root/.my.cnf', '/etc/my.cnf.d/server.cnf', '/etc/my.cnf.d/client.cnf'
    ],
    'Debian' => [
      '/usr/bin/galera_wizard.py', '/root/galera_params.py',
      '/root/.my.cnf', '/etc/mysql/my.cnf'
    ],
  }

  if ($manage_lvm) {
    $require_list = [File[$file_list], Package[$galera_package], Mount['/var/lib/mysql']]
  } else {
    $require_list = [File[$file_list], Package[$galera_package]]
  }

  unless defined(Exec['bootstrap_or_join']) {
    exec { 'bootstrap_or_join':
      command => 'galera_wizard.py -bn -f || galera_wizard.py -jn -f',
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      creates => $joined_file,
      returns => [0,1],
      require => $require_list;
    }
  }

  if ($::galera_joined_exist and $::galera_status != '200') {
    unless defined(Exec['join_existing']) {
      exec { 'join_existing':
        command => 'galera_wizard.py -je',
        path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
        returns => [0,1],
        require => $require_list;
      }
    }
  } else {
    unless defined(Exec['join_existing']) {
      exec { 'join_existing':
        command     => 'echo',
        path        => '/usr/bin:/bin',
        refreshonly => true;
      }
    }
  }

  if ($::galera_joined_exist and $::galera_status == '200') {
    galera_maxscale::create_user {
      'sstuser':
        galera_hosts   => $galera_hosts,
        maxscale_hosts => $maxscale_hosts,
        maxscale_vip   => $maxscale_vip,
        dbpass         => $sst_password;
      'monitor':
        galera_hosts   => $galera_hosts,
        maxscale_hosts => $maxscale_hosts,
        maxscale_vip   => $maxscale_vip,
        dbpass         => $monitor_password;
    }
    if $maxscale_password {
      galera_maxscale::create_user { 'maxscale':
        galera_hosts   => $galera_hosts,
        maxscale_hosts => $maxscale_hosts,
        maxscale_vip   => $maxscale_vip,
        dbpass         => $maxscale_password;
      }
    }
  }

}
