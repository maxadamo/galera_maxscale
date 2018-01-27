
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
    if ($maxscale_hosts) {
      $host_hash = deep_merge($galera_hosts, $maxscale_hosts, $maxscale_vip)
    } else {
      $host_hash = $galera_hosts
    }
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

  $host_hash.each | $host_name, $host_ips | {
    mysql_user {
      "${dbuser}@${host_ips['ipv4']}":
        ensure        => present,
        password_hash => mysql_password($dbpass),
        provider      => 'mysql';
      "${dbuser}@${host_name}":
        ensure        => present,
        password_hash => mysql_password($dbpass),
        provider      => 'mysql';
    }
    mysql_grant {
      "${dbuser}@${host_ips['ipv4']}/${table}":
        ensure     => present,
        user       => "${dbuser}@${host_ips['ipv4']}",
        table      => $table,
        privileges => $privileges,
        require    => Mysql_user["${dbuser}@${host_ips['ipv4']}"];
      "${dbuser}@${host_name}/${table}":
        ensure     => present,
        user       => "${dbuser}@${host_name}",
        table      => $table,
        privileges => $privileges,
        require    => Mysql_user["${dbuser}@${host_name}"];
    }
  }

}
