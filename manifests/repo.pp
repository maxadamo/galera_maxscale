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
        exec { 'wake_me_up_before_run':
          command     => '/usr/bin/apt-get update',
          refreshonly => true,
        }
        apt::key {
          default:
            server  => 'keyserver.ubuntu.com',
            options => $options;
          'mariadb_10_2':
            id     => '177F4010FE56CA3336300305F1656F24C74CD1D8',
            before => [
              Apt::Source['percona_release'],
              Class['::galera_maxscale::install']
            ];
          'percona_release':
            id     => '430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A',
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
            notify  => Exec['wake_me_up_before_run'];
          'percona_release':
            location => 'http://repo.percona.com/apt',
            release  => $::lsbdistcodename;
          'mariadb_10_2':
            location     => 'http://mirrors.supportex.net/mariadb/repo/10.2/ubuntu',
            architecture => 'amd64,i386',
            release      => $::lsbdistcodename;
        }
        #deb http://repo.percona.com/apt xenial main
        #deb-src http://repo.percona.com/apt xenial main
        # MariaDB 10.2 repository list - created 2018-01-25 16:44 UTC
        # http://downloads.mariadb.org/mariadb/repositories/
        # deb [arch=amd64,i386] http://mirrors.supportex.net/mariadb/repo/10.2/ubuntu xenial main
        # deb-src http://mirrors.supportex.net/mariadb/repo/10.2/ubuntu xenial main
      }

      default: {
        fail("${::osfamily} not yet supported")
      }
    }
  }

}
