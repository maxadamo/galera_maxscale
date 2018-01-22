# == Define: galera_maxscale::root_password
#
# == Overview
#
# if the password was changed on one node, it will fail in the other nodes
# we need to let it fail and check it again, with the new password
#
define galera_maxscale::root_password () {

  $root_password = $name
  $pw_change_cmd = "mysqladmin -u root --\$(grep 'password=') password ${root_password}"
  $old_pw_check = "mysql -u root --password=\$(grep 'password=') -e \"select 1 from dual\""
  $new_pw_check = "mysql -u root --password=${root_password} -e \"select 1 from dual\""

  exec { 'change_root_password':
    command => $pw_change_cmd,
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => $new_pw_check,
    onlyif  => 'test -f /root/.my.cnf',
    before  => File['/root/.my.mcf'];
  }

}
