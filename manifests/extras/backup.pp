# == Class: galera_maxscale::extras::backup
#
# WIP: BROKEN. Don't use it!
#
# This Class will setup a daily hot-backup
#
#
class galera_maxscale::extras::backup (
  $daily_hotbackup     = $::galera_maxscale::params::daily_hotbackup,
  $galera_cluster_name = $::galera_maxscale::params::galera_cluster_name,
  ) {

  # Create directory tree for backup and mount it
  if ($daily_hotbackup) {
    file {
      '/mnt/galera_backup':
        ensure => directory;
      "/mnt/galera_backup/${galera_cluster_name}":
        ensure  => directory,
        require => Mount['/mnt/galera_backup'];
    }

    mount { '/mnt/galera_backup':
      ensure   => mounted,
      device   => "${galera_maxscale::my_backup_device}:/vol/prod_${galera_maxscale::my_site}_galera_backup",
      fstype   => 'nfs',
      options  => 'noatime',
      remounts => true,
      require  => File['/mnt/galera_backup'];
    }

    # Crontab entry to run daily backups only on the second node
    if $::fqdn == (inline_template('<%= @nodes.sort[1] %>')) {
      notify { '2nd node of the cluster: setting up daily hot-backup': }
      cron::tab { "${::application}-backup-script":
        command => '/root/bin/hotbackup.sh',
        user    => 'root',
        hour    => fqdn_rand(7),
        minute  => fqdn_rand(60),
      }
    }
  }

}
