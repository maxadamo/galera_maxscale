# == Class: galera::repo inherits galera
#
class galera::repo (
  $manage_repo = $::galera::params::manage_repo
  ) inherits galera {

  if ($manage_repo) {

    case $::osfamily {
      'RedHat', 'CentOS': {
        rpmkey { '1BB943DB':
          ensure => present,
          source => 'http://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
          before => Class['::galera::install'];
        }
        yumrepo { 'MariaDB':
          baseurl    => 'http://yum.mariadb.org/10.2/centos7-amd64',
          descr      => 'The MariaDB repository',
          enabled    => '1',
          gpgcheck   => '1',
          gpgkey     => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
          mirrorlist => '',
          require    => Rpmkey['1BB943DB'];
        }
      }

      /^(Debian|Ubuntu)$/: {
        # do something to add apt repo
        package { 'percona-release':
          ensure   => installed,
          provider => 'deb',
          source   => "https://repo.percona.com/apt/percona-release_0.1-4.${::codename}_all.deb";
        }
      }

      default: {
        fail("${::osfamily} not yet supported")
      }
    }
  }

}
