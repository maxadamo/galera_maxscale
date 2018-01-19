# == Class: galera_maxscale::extras::monitoring
#
# Monitoring Class
#
class galera_maxscale::extras::monitoring (
  $user  = undef,
  $group = undef,
) {

  # generic monitoring script
  file {
    '/etc/monitor.cnf':
      owner   => $user,
      group   => $group,
      mode    => '0660',
      content => template("${module_name}/etc/monitor.cnf.erb");
    '/usr/local/bin/check_mysql.sh':
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template("${module_name}/etc/check_mysql.sh.erb");
  }

}
