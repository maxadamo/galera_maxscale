# == Class: galera_maxscale::backup
#
# This Class sets up a daily hot-backup
# You may need to provide sufficient space in the mount point $backup_dir.
#
# The backup will run only on one node: I decided to pick the 2nd node.
#
#
class galera_maxscale::backup (
  $daily_hotbackup     = $::galera_maxscale::params::daily_hotbackup,
  $galera_cluster_name = $::galera_maxscale::params::galera_cluster_name,
  $backup_dir          = $::galera_maxscale::params::backup_dir,
  ) {

  # Create directory tree for backup and mount it
  if ($daily_hotbackup) {
    unless Defined(File[$backup_dir]) {
      file { $backup_dir:
        ensure => directory,
        before => File["${backup_dir}/${galera_cluster_name}"];
      }
    }
    file { "${backup_dir}/${galera_cluster_name}":
      ensure  => directory;
    }

    # Crontab entry to run daily backups only on the second node
    if $::fqdn == (inline_template('<%= @nodes.sort[1] %>')) {
      notify { '2nd node of the cluster: setting up daily hot-backup': }
      cron::tab { "${galera_cluster_name}-${::hostname}-backup-script":
        command => '/root/bin/hotbackup.sh',
        user    => 'root',
        hour    => fqdn_rand(7),
        minute  => fqdn_rand(60),
      }
    }
  }

}
