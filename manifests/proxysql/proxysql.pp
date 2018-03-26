# == Class: galera_maxscale::proxysql::proxysql
#
# === Parameters & Variables
#
# [*galera_hosts*] <Hash>
#   list of hosts, ipv4 (optionally ipv6) belonging to the cluster: not less than 3, not even.
#   check examples on README.md
#
# [*maxscale_hosts*] <Hash>
#   list of hosts, ipv4 (optionally ipv6) belonging to MaxScale cluster.
#   Currently only 2 hosts are supported. Check examples on README.md
#
# [*maxscale_vip*] <Hash>
#   host, ipv4 (optionally ipv6) for the VIP
#
# [*maxscale_password*] <String>
#   maxscale user password
#
# [*trusted_networks*] <Array>
#   default: undef => List of IPv4 and/or IPv6 host and or networks.
#            It's used by iptables to determine from where to allow access to MySQL
#
# [*manage_repo*] <Bool>
#   default: true => please check repo.pp to understand what repos are neeeded
#
# [*http_proxy*] <String>
#   default: undef  http proxy used for instance by gpg key
#   Example: 'http://proxy.example.net:8080'
#
#
class galera_maxscale::proxysql::proxysql (
  $percona_major_version  = $::galera_maxscale::params::mariadb_major_version,
  $maxscale_major_version = $::galera_maxscale::params::maxscale_major_version,
  $galera_hosts           = $::galera_maxscale::params::galera_hosts,
  $manage_repo            = $::galera_maxscale::params::manage_repo,
  $maxscale_hosts         = $::galera_maxscale::params::maxscale_hosts,
  $maxscale_vip           = $::galera_maxscale::params::maxscale_vip,
  $maxscale_password      = $::galera_maxscale::params::maxscale_password,
  $trusted_networks       = $::galera_maxscale::params::trusted_networks,
  $http_proxy             = $::galera_maxscale::params::http_proxy,
  $network_interface      = $::galera_maxscale::params::network_interface,
  $maxscale_version       = $::galera_maxscale::params::maxscale_version
  ) inherits galera_maxscale::params {

  $maxscale_key_first = inline_template('<% @maxscale_hosts.each_with_index do |(key, value), index| %><% if index == 0 %><%= key %><% end -%><% end -%>')
  $vip_key = inline_template('<% @maxscale_vip.each do |key, value| %><%= key %><% end -%>')
  $vip_ip = $maxscale_vip[$vip_key]['ipv4']
  if has_key($maxscale_hosts[$maxscale_key_first], 'ipv6') {
    $ipv6_true = true
  } else {
    $ipv6_true = undef
  }

  class {
    '::galera_maxscale::repo':
      http_proxy  => $http_proxy,
      manage_repo => $manage_repo;
    '::galera_maxscale::proxysql::keepalived':
      manage_ipv6       => $ipv6_true,
      maxscale_hosts    => $maxscale_hosts,
      network_interface => $network_interface,
      maxscale_vip      => $maxscale_vip;
    '::galera_maxscale::firewall':
      manage_ipv6      => $ipv6_true,
      galera_hosts     => $galera_hosts,
      maxscale_hosts   => $maxscale_hosts,
      maxscale_vip     => $maxscale_vip,
      trusted_networks => $trusted_networks;
  }

  service { 'proxysql':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    provider   => 'redhat',
    require    => Package['proxysql'];
  }

  unless any2bool($manage_repo) == false {
    package {
      default:
        require => Yumrepo['Percona'];
      "Percona-Server-shared-compat-${percona_major_version}":
        ensure => installed,
        before => Package["Percona-Server-client-${percona_major_version}"];
      "Percona-Server-client-${percona_major_version}":
        ensure => installed,
        before => Package['proxysql'];
      'proxysql':
        ensure  => $maxscale_version;
    }
  } else {
    package {
      "Percona-Server-shared-compat-${percona_major_version}":
        ensure => installed,
        before => Package["Percona-Server-client-${percona_major_version}"];
      "Percona-Server-client-${percona_major_version}":
        ensure => installed,
        before => Package['proxysql'];
      'proxysql':
        ensure  => $maxscale_version;
    }
  }

  file {
    default:
      default => '0755',
      owner   => proxysql,
      group   => proxysql,
      require => Package['proxysql'],
      notify  => Service['proxysql'];
    '/etc/proxysql.cnf':
      ensure  => file,
      mode    => '0640',
      before  => File['/etc/init.d/proxysql'],
      content => template("${module_name}/proxysql.cnf.erb");
    '/etc/init.d/proxysql':
      ensure => file,
      source => "puppet:///modules/${module_name}/proxysql";
    '/var/lib/mysql':
      ensure => directory;
  }

  # we need a fake exec in common with galera nodes to let
  # galera use the `before` statement in the same firewall
  unless defined(Exec['bootstrap_or_join']) {
    exec { 'bootstrap_or_join':
      command     => 'echo',
      path        => '/usr/bin:/bin',
      refreshonly => true;
    }
  }
  unless defined(Exec['join_existing']) {
    exec { 'join_existing':
      command     => 'echo',
      path        => '/usr/bin:/bin',
      refreshonly => true;
    }
  }

}
