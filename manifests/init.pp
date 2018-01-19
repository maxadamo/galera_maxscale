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
class galera_maxscale (

  $all_pkgs                     = $::galera_maxscale::params::all_pkgs,
  $backup_compress              = $::galera_maxscale::params::backup_compress,
  $backup_retention             = $::galera_maxscale::params::backup_retention,
  $daily_hotbackup              = $::galera_maxscale::params::daily_hotbackup,
  $datadir                      = $::galera_maxscale::params::datadir,
  $galera_cluster_name          = $::galera_maxscale::params::galera_cluster_name,
  $galera_hosts                 = $::galera_maxscale::params::galera_hosts,
  $galera_pkgs                  = $::galera_maxscale::params::galera_pkgs,
  $galera_total_memory_usage    = $::galera_maxscale::params::galera_total_memory_usage,
  $galera_version               = $::galera_maxscale::params::galera_version,
  $innodb_buffer_pool_instances = $::galera_maxscale::params::innodb_buffer_pool_instances,
  $innodb_flush_method          = $::galera_maxscale::params::innodb_flush_method,
  $innodb_io_capacity           = $::galera_maxscale::params::innodb_io_capacity,
  $innodb_log_file_size         = $::galera_maxscale::params::innodb_log_file_size,
  $logdir                       = $::galera_maxscale::params::logdir,
  $lv_size                      = $::galera_maxscale::params::lv_size,
  $manage_firewall              = $::galera_maxscale::params::manage_firewall,
  $manage_lvm                   = $::galera_maxscale::params::manage_lvm,
  $manage_repo                  = $::galera_maxscale::params::manage_repo,
  $max_connections              = $::galera_maxscale::params::max_connections,
  $maxscale_hosts               = $::galera_maxscale::params::maxscale_hosts,
  $maxscale_vip                 = $::galera_maxscale::params::maxscale_vip,
  $maxscale_password            = $::galera_maxscale::params::maxscale_password,
  $monitor_password             = $::galera_maxscale::params::monitor_password,
  $monitor_username             = $::galera_maxscale::params::monitor_username,
  $other_pkgs                   = $::galera_maxscale::params::other_pkgs,
  $query_cache                  = $::galera_maxscale::params::query_cache,
  $root_password                = $::galera_maxscale::params::root_password,
  $slow_query_time              = $::galera_maxscale::params::slow_query_time,
  $sst_password                 = $::galera_maxscale::params::sst_password,
  $thread_cache_size            = $::galera_maxscale::params::thread_cache_size,
  $tmpdir                       = $::galera_maxscale::params::tmpdir,
  $trusted_networks             = $::galera_maxscale::params::trusted_networks,
  $version                      = $::galera_maxscale::params::version,

) inherits galera_maxscale::params {

  $cluster_size = inline_template('<%= @galera_hosts.keys.count %>')
  $cluster_size_odd = inline_template('<% if @galera_hosts.keys.count.to_i.odd? -%>true<% end -%>')

  if $cluster_size+0 < 3 { fail('a cluster must have at least 3 nodes') }
  unless $cluster_size_odd { fail('the number of nodes in the cluster must be odd')}
  unless $root_password { fail('parameter "root_password" is missing') }
  unless $sst_password { fail('parameter "sst_password" is missing') }
  unless $monitor_password { fail('parameter "monitor_password" is missing') }

  if $manage_lvm and $lv_size == undef { fail('manage_lvm is true but lv_size is undef') }
  if $manage_lvm == undef and $lv_size { fail('manage_lvm is undeef but lv_size is defined') }

  class { 'galera_maxscale::repo':
    manage_repo => $manage_repo;
  }
  class { 'galera_maxscale::install':
    galera_pkgs => $galera_pkgs,
    other_pkgs  => $other_pkgs;
  }

  class { 'galera_maxscale::lvm': lv_size => $lv_size; }

  class { 'galera_maxscale::services':; }

  class { 'galera_maxscale::files':
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
    class { 'galera_maxscale::firewall':
      manage_ipv6      => $ipv6_true,
      galera_hosts     => $galera_hosts,
      trusted_networks => $trusted_networks;
    }
  }

  class { '::galera_maxscale::join':
    monitor_password  => $monitor_password,
    root_password     => $root_password,
    sst_password      => $monitor_password,
    maxscale_password => $maxscale_password,
    galera_hosts      => $galera_hosts,
    maxscale_hosts    => $maxscale_hosts,
    maxscale_vip      => $maxscale_vip;
  }

  include ::galera_maxscale::extras::backup

}
