# == Class: galera_maxscale::repo inherits galera
#
class galera_maxscale::repo (
  $http_proxy  = $::galera_maxscale::params::http_proxy,
  $manage_repo = $::galera_maxscale::params::manage_repo
  ) inherits galera_maxscale::params {

  if ($manage_repo) {

    if ($http_proxy) { $options = "http-proxy=\"${http_proxy}\"" } else { $options = undef }

    case $::operatingsystem {
      'RedHat', 'CentOS': {
        rpmkey {
          '1BB943DB':
            ensure => present,
            source => 'http://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
            before => Class['::galera_maxscale::install'];
          'CD2EFD2A':
            ensure => present,
            source => 'http://www.percona.com/downloads/RPM-GPG-KEY-percona',
            before => Class['::galera_maxscale::install'];
        }
        yumrepo {
          'MariaDB':
            baseurl    => 'http://yum.mariadb.org/10.2/centos7-amd64',
            descr      => 'The MariaDB repository',
            enabled    => '1',
            gpgcheck   => '1',
            gpgkey     => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
            mirrorlist => '',
            require    => Rpmkey['1BB943DB'];
          'percona_release_noarch':
            baseurl    => 'http://repo.percona.com/release/$releasever/RPMS/noarch',
            descr      => 'Percona-Release YUM repository',
            enabled    => '1',
            gpgcheck   => '1',
            gpgkey     => 'http://www.percona.com/downloads/RPM-GPG-KEY-percona',
            mirrorlist => '',
            require    => Rpmkey['CD2EFD2A'];
        }
      }
      'Ubuntu': {
        apt::key {
          default:
            server  => 'hkp://keyserver.ubuntu.com:80',
            options => $options;
          'mariadb_10_2':
            id     => '177F4010FE56CA3336300305F1656F24C74CD1D8',
            before => [
              Apt::Source['percona_release'],
              Class['::galera_maxscale::install']
            ];
          'percona_release':
            id     => '4D1BB29D63D98E422B2113B19334A25F8507EFA5',
            before => [
              Apt::Source['percona_release'],
              Class['::galera_maxscale::install']
            ];
        }
        apt::source {
          default:
            repos   => 'main',
            include => {
              'src' => true,
              'deb' => true,
            },
            notify  => Exec['apt_update'];
          'percona_release':
            location => 'http://repo.percona.com/apt',
            release  => $::lsbdistcodename;
          'mariadb_10_2':
            location     => 'http://mirrors.supportex.net/mariadb/repo/10.2/ubuntu',
            architecture => 'amd64,i386',
            release      => $::lsbdistcodename;
        }
      }
      default: {
        fail("${::operatingsystem} not yet supported")
      }
    }
  }

}
