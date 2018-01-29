# == Class: galera_maxscale::maxscale::maxscale
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
class galera_maxscale::maxscale::maxscale (
  $galera_major_version = $::galera_maxscale::params::galera_major_version,
  $galera_hosts         = $::galera_maxscale::params::galera_hosts,
  $manage_repo          = $::galera_maxscale::params::manage_repo,
  $maxscale_hosts       = $::galera_maxscale::params::maxscale_hosts,
  $maxscale_vip         = $::galera_maxscale::params::maxscale_vip,
  $maxscale_password    = $::galera_maxscale::params::maxscale_password,
  $trusted_networks     = $::galera_maxscale::params::trusted_networks,
  $http_proxy           = $::galera_maxscale::params::http_proxy,
  $network_interface    = $::galera_maxscale::params::network_interface,
  $maxscale_version     = $::galera_maxscale::params::maxscale_version
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
    '::galera_maxscale::maxscale::repo':
      galera_major_version => $galera_major_version,
      http_proxy           => $http_proxy,
      manage_repo          => $manage_repo;
    '::galera_maxscale::maxscale::keepalived':
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

  unless any2bool($manage_repo) == false {
    case $::operatingsystem {
      'CentOS', 'RedHat': {
        package { 'maxscale':
          ensure  => $maxscale_version,
          require => Yumrepo['MaxScale'];
        }
      }
      'Ubuntu': {
        package { 'maxscale':
          ensure  => $maxscale_version,
          require => [Exec['apt_update'], Apt::Source['maxscale']];
        }
      }
      default: {
        fail("${::operatingsystem} not supported")
      }
    }
  } else {
    package { 'maxscale': ensure => $maxscale_version; }
  }

  service { 'maxscale':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['maxscale'];
  }

  file { '/etc/maxscale.cnf':
    ensure  => file,
    owner   => maxscale,
    group   => maxscale,
    mode    => '0640',
    require => Package['maxscale'],
    content => template("${module_name}/maxscale.cnf.erb"),
    notify  => Service['maxscale'];
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
