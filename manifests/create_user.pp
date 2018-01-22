
# == Define: galera_maxscale::create_user
#
define galera_maxscale::create_user (
  $dbpass,
  $galera_hosts,
  $maxscale_hosts,
  $maxscale_vip,
  $dbuser = $name
  ) {

  if $dbuser == 'maxscale' {
    $host_hash = deep_merge($galera_hosts, $maxscale_hosts, $maxscale_vip)
    $privileges = ['SELECT', 'SHOW DATABASES', 'REPLICATION CLIENT']
    $table = '*.*'
  } elsif $dbuser == 'sstuser' {
    $host_hash = $galera_hosts
    $privileges = ['PROCESS', 'SELECT', 'RELOAD', 'LOCK TABLES', 'REPLICATION CLIENT']
    $table = '*.*'
  } elsif $dbuser == 'monitor' {
    $host_hash = $galera_hosts
    $privileges = ['UPDATE']
    $table = 'test.monitor'
  }

  $_host_list = keys($host_hash)
  $host_list = concat($_host_list, 'localhost')

  $host_list.each | String $peer | {
    mysql_user { "${dbuser}@${peer}":
      ensure        => present,
      password_hash => mysql_password($dbpass),
      provider      => 'mysql';
    }
    -> mysql_grant { "${dbuser}@${peer}/${table}":
      ensure     => present,
      user       => "${dbuser}@${peer}",
      table      => $table,
      privileges => $privileges;
    }
  }

}
