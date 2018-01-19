# == Class: galera
#
# Setup Galera MariaDB Cluster and MaxScale
#
# == Quick Overview
#
# (see file README.md )
#
# === Parameters & Variables
#
# WIP
#
# === ToDo
#
# - List all parameters
# - Add root password change
#
# === Authors
#
# 2018-Jan-15: Massimiliano Adamo <maxadamo@gmail.com>
#
class galera (

  $all_pkgs                     = $::galera::params::all_pkgs,
  $backup_compress              = $::galera::params::backup_compress,
  $backup_retention             = $::galera::params::backup_retention,
  $daily_hotbackup              = $::galera::params::daily_hotbackup,
  $datadir                      = $::galera::params::datadir,
  $galera_cluster_name          = $::galera::params::galera_cluster_name,
  $galera_hosts                 = $::galera::params::galera_hosts,
  $galera_pkgs                  = $::galera::params::galera_pkgs,
  $galera_total_memory_usage    = $::galera::params::galera_total_memory_usage,
  $galera_version               = $::galera::params::galera_version,
  $innodb_buffer_pool_instances = $::galera::params::innodb_buffer_pool_instances,
  $innodb_flush_method          = $::galera::params::innodb_flush_method,
  $innodb_io_capacity           = $::galera::params::innodb_io_capacity,
  $innodb_log_file_size         = $::galera::params::innodb_log_file_size,
  $logdir                       = $::galera::params::logdir,
  $lv_size                      = $::galera::params::lv_size,
  $manage_firewall              = $::galera::params::manage_firewall,
  $manage_lvm                   = $::galera::params::manage_lvm,
  $manage_repo                  = $::galera::params::manage_repo,
  $max_connections              = $::galera::params::max_connections,
  $maxscale_hosts               = $::galera::params::maxscale_hosts,
  $maxscale_vip                 = $::galera::params::maxscale_vip,
  $maxscale_password            = $::galera::params::maxscale_password,
  $monitor_password             = $::galera::params::monitor_password,
  $monitor_username             = $::galera::params::monitor_username,
  $other_pkgs                   = $::galera::params::other_pkgs,
  $query_cache                  = $::galera::params::query_cache,
  $root_password                = $::galera::params::root_password,
  $slow_query_time              = $::galera::params::slow_query_time,
  $sst_password                 = $::galera::params::sst_password,
  $thread_cache_size            = $::galera::params::thread_cache_size,
  $tmpdir                       = $::galera::params::tmpdir,
  $trusted_networks             = $::galera::params::trusted_networks,
  $version                      = $::galera::params::version,

) inherits galera::params {

  $cluster_size = inline_template('<%= @galera_hosts.keys.count %>')
  $cluster_size_odd = inline_template('<% if @galera_hosts.keys.count.to_i.odd? -%>true<% end -%>')

  if $cluster_size+0 < 3 { fail('a cluster must have at least 3 nodes') }
  unless $cluster_size_odd { fail('the number of nodes in the cluster must be odd')}
  unless $root_password { fail('parameter "root_password" is missing') }
  unless $sst_password { fail('parameter "sst_password" is missing') }
  unless $monitor_password { fail('parameter "monitor_password" is missing') }

  if $manage_lvm and $lv_size == undef { fail('manage_lvm is true but lv_size is undef') }
  if $manage_lvm == undef and $lv_size { fail('manage_lvm is undeef but lv_size is defined') }

  class { 'galera::repo':
    manage_repo => $manage_repo;
  }
  class { 'galera::install':
    galera_pkgs => $galera_pkgs,
    other_pkgs  => $other_pkgs;
  }

  class { 'galera::lvm': lv_size => $lv_size; }

  class { 'galera::services':; }

  class { 'galera::files':
    backup_compress              => $backup_compress,
    backup_retention             => $backup_retention,
    datadir                      => $datadir,
    galera_cluster_name          => $galera_cluster_name,
    galera_hosts                 => $galera_hosts,
    innodb_buffer_pool_instances => $innodb_buffer_pool_instances,
    innodb_flush_method          => $innodb_flush_method,
    innodb_io_capacity           => $innodb_io_capacity,
    innodb_log_file_size         => $innodb_log_file_size,
    logdir                       => $logdir,
    max_connections              => $max_connections,
    monitor_password             => $monitor_password,
    monitor_username             => $monitor_username,
    query_cache                  => $query_cache,
    root_password                => $root_password,
    sst_password                 => $sst_password,
    tmpdir                       => $tmpdir,
    thread_cache_size            => $thread_cache_size,
    slow_query_time              => $slow_query_time,
  }

  $galera_first_key = inline_template('<% @galera_hosts.each_with_index do |(key, value), index| %><% if index == 0 %><%= key %><% end -%><% end -%>')
  if has_key($galera_hosts[$galera_first_key], 'ipv6') {
    $ipv6_true = true
  } else {
    $ipv6_true = undef
  }

  if $manage_firewall {
    class { 'galera::firewall':
      manage_ipv6      => $ipv6_true,
      galera_hosts     => $galera_hosts,
      trusted_networks => $trusted_networks;
    }
  }

  class { '::galera::join':
    monitor_password  => $monitor_password,
    root_password     => $root_password,
    sst_password      => $monitor_password,
    maxscale_password => $maxscale_password,
    galera_hosts      => $galera_hosts,
    maxscale_hosts    => $maxscale_hosts,
    maxscale_vip      => $maxscale_vip;
  }

  include ::galera::extras::backup

}
