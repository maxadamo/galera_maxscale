# == Class: galera_maxscale::maxscale::repo
#
class galera_maxscale::maxscale::repo ($manage_repo) {

  if ($manage_repo) {

    case $::osfamily {
      'RedHat', 'CentOS': {
        rpmkey { '28C12247':
          ensure => present,
          source => 'https://downloads.mariadb.com/MaxScale/MariaDB-MaxScale-GPG-KEY',
          before => Class['::galera_maxscale::install'];
        }
        yumrepo { 'MaxScale':
          baseurl    => 'https://downloads.mariadb.com/MaxScale/2.1/rhel/$releasever/$basearch',
          descr      => 'The MariaDB repository',
          enabled    => '1',
          gpgcheck   => '1',
          gpgkey     => 'https://downloads.mariadb.com/MaxScale/MariaDB-MaxScale-GPG-KEY',
          mirrorlist => '',
          require    => Rpmkey['28C12247'];
        }
      }

      /^(Debian|Ubuntu)$/: {
        fail('Debian/Ubuntu not yet supported')
      }

      default: {
        fail("${::osfamily} not yet supported")
      }
    }
  }

}
