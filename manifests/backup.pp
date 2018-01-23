# == Class: galera_maxscale::backup
#
# This Class sets up a daily hot-backup
# You may need to provide sufficient space in the mount point $backup_dir.
#
# The backup will run only on one node: I decided to pick the 2nd node.
#
#
class galera_maxscale::backup (
  $galera_hosts        = $::galera_maxscale::params::galera_hosts,
  $daily_hotbackup     = $::galera_maxscale::params::daily_hotbackup,
  $galera_cluster_name = $::galera_maxscale::params::galera_cluster_name,
  $backup_dir          = $::galera_maxscale::params::backup_dir,
  ) {

  # Create directory tree for backup and mount it
  if ($daily_hotbackup) {
    exec { 'make_backup_dir':
      command => "mkdir -p ${backup_dir}/${galera_cluster_name}",
      path    => '/usr/bin:/usr/sbin:/bin',
      unless  => "test -d ${backup_dir}/${galera_cluster_name}"
    }

    $nodes = keys($galera_hosts)

    # Crontab entry to run daily backups only on the second node
    if $::fqdn == (inline_template('<%= @nodes.sort[1] %>')) {
      notify { '2nd node of the cluster: setting up daily hot-backup': }
      cron { "${galera_cluster_name}-${::hostname}-backup-script":
        command => '/root/bin/hotbackup.sh',
        user    => 'root',
        hour    => fqdn_rand(7),
        minute  => fqdn_rand(60),
      }
    }
  }

}
