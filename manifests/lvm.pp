# == Class: galera_maxscale::lvm
#
class galera_maxscale::lvm (
  $manage_lvm = $::galera_maxscale::params::manage_lvm,
  $lv_size = $::galera_maxscale::params::lv_size,
  $vg_name = $::galera_maxscale::params::vg_name,
  $datadir = $::galera_maxscale::params::datadir
  ) inherits galera_maxscale::params {

  if ($lv_size and $manage_lvm and $vg_name) {
    logical_volume { 'lv_galera':
      ensure       => present,
      volume_group => $vg_name,
      size         => "${lv_size}G",
    }

    filesystem { "/dev/mapper/${vg_name}-lv_galera":
      ensure  => present,
      fs_type => 'ext4',
      require => Logical_volume['lv_galera']
    }

    file { $datadir:
      ensure  => directory,
      mode    => '0755',
      owner   => mysql,
      group   => mysql,
      require => Package['MariaDB-server'];
    }

    mount { $datadir:
      ensure  => mounted,
      fstype  => 'ext4',
      atboot  => true,
      device  => "/dev/mapper/${vg_name}-lv_galera",
      require => [
        File[$datadir],
        Filesystem["/dev/mapper/${vg_name}-lv_galera"]
      ],
      notify  => Exec['fix_permissions'];
    }

    exec { 'fix_datadir_permissions':
      command => "chown mysql:mysql ${datadir}",
      path    => '/usr/bin:/usr/sbin:/bin',
      unless  => 'stat -c "%U%G" /etc/grafana/|grep "mysqlmysql"';
    }
  }

}
