# == Class: galera_maxscale::repo inherits galera
#
class galera_maxscale::repo (
  $manage_repo = $::galera_maxscale::params::manage_repo
  ) inherits galera_maxscale::params {

  if ($manage_repo) {

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
        package { 'percona-release':
          ensure   => installed,
          provider => 'deb',
          source   => "https://repo.percona.com/apt/percona-release_0.1-4.${::codename}_all.deb",
          notify   => Exec['wake_me_up_before_run'];
        }
        apt::key { 'mariadb_10_2':
          id      => '177F4010FE56CA3336300305F1656F24C74CD1D8',
          server  => 'keyserver.ubuntu.com',
          options => 'http-proxy="http://proxy.geant.net:8080"',
          before  => Apt::Source['mariadb_10_2'];
        }
        apt::source { 'mariadb_10_2':
          location     => 'http://mirrors.supportex.net/mariadb/repo/10.2/ubuntu',
          architecture => 'amd64,i386',
          release      => $::lsbdistcodename,
          repos        => 'main',
          include      => {
            'src' => true,
            'deb' => true,
          },
          notify       => Exec['wake_me_up_before_run'];
        }
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
