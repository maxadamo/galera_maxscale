# == Define: galera_maxscale::root_password
#
# == Overview
#
# if the password was changed on one node, it will fail in the other nodes
# we need to let it fail and check it again, with the new password
#
define galera_maxscale::root_password () {

  $root_cnf_exist = inline_template("<% if File.exist?('/root/.my.cnf') -%>yes<% else %>no<% end -%>")

  if $root_cnf_exist == 'yes' {

    $root_password = $name
    $old_password = inline_template("<%= File.open('/root/.my.cnf').grep(/password=/)[0].chomp %>")
    $pw_change_cmd = "mysqladmin -u root --password=${old_password} password ${root_password}"
    $old_pw_check = "mysql -u root --password=${old_password} -e \"select 1 from dual\""
    $new_pw_check = "mysql -u root --password=${root_password} -e \"select 1 from dual\""

    if $root_password != $old_password {
      exec {
        'change_root_password':
          command => $pw_change_cmd,
          path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
          unless  => $old_pw_check,
          onlyif  => 'test -f /root/.my.cnf',
          notify  => Exec['check_root_password'],
          before  => File['/root/.my.mcf'];
        'check_new_password':
          command     => $new_pw_check,
          path        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
          refreshonly => true;
      }
    }
  }

}
