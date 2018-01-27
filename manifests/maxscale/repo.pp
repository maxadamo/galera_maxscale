# == Class: galera_maxscale::maxscale::repo
#
class galera_maxscale::maxscale::repo (
  $manage_repo = $::galera_maxscale::params::manage_repo,
  $http_proxy  = $::galera_maxscale::params::http_proxy,
  ) {

  if ($manage_repo) {

    if ($http_proxy) { $options = "http-proxy=\"${http_proxy}\"" } else { $options = undef }

    case $::operatingsystem {
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
      'Ubuntu': {
        apt::key { 'maxscale':
          id      => '7B963F525AD3AE6259058D30135659E928C12247',
          server  => 'hkp://keyserver.ubuntu.com:80',
          options => $options;
        }
        apt::source { 'maxscale':
          location     => 'https://downloads.mariadb.com/MaxScale/2.2.1/ubuntu',
          architecture => 'amd64,i386',
          repos        => 'main',
          include      => {
            'deb' => true,
          },
          notify       => Exec['apt_update'],
          release      => $::lsbdistcodename,
          require      => Apt::Key['maxscale'];
        }
      }
      default: {
        fail("${::operatingsystem} not supported")
      }
    }
  }

}
