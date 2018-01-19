# == Class: galera::lvm
#
class galera::lvm (
  $manage_lvm = $::galera::params::manage_lvm,
  $lv_size = $::galera::params::lv_size
  ) inherits galera::params {

  if ($lv_size and $manage_lvm) {
    logical_volume { 'lv_galera':
      ensure       => present,
      volume_group => 'rootvg',
      size         => "${lv_size}G",
    }

    filesystem { '/dev/mapper/rootvg-lv_galera':
      ensure  => present,
      fs_type => 'ext4',
      require => Logical_volume['lv_galera']
    }

    file { '/var/lib/mysql':
      ensure  => directory,
      mode    => '0755',
      owner   => mysql,
      group   => mysql,
      require => Package['MariaDB-server'];
    }

    mount { '/var/lib/mysql':
      ensure  => mounted,
      fstype  => 'ext4',
      atboot  => true,
      device  => '/dev/mapper/rootvg-lv_galera',
      require => [
        File['/var/lib/mysql'],
        Filesystem['/dev/mapper/rootvg-lv_galera']
      ],
      notify  => Exec['fix_permissions'];
    }

    exec { 'fix_permissions':
      command     => 'chown -R mysql:mysql /var/lib/mysql',
      path        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      refreshonly => true;
    }
  }

}
