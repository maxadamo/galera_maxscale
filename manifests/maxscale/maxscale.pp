# == Class: galera::maxscale::maxscale
#
class galera::maxscale::maxscale (
  $galera_hosts      = $::galera::params::galera_hosts,
  $maxscale_hosts    = $::galera::params::maxscale_hosts,
  $maxscale_vip      = $::galera::params::maxscale_vip,
  $maxscale_password = $::galera::params::maxscale_password,
  $trusted_networks  = $::galera::params::trusted_networks
  ) inherits galera::params {

  $maxscale_key_first = inline_template('<% @maxscale_hosts.each_with_index do |(key, value), index| %><% if index == 0 %><%= key %><% end -%><% end -%>')
  $vip_key = inline_template('<% @maxscale_vip.each do |key, value| %><%= key %><% end -%>')
  $vip_ip = $maxscale_vip[$vip_key]['ipv4']
  if has_key($maxscale_hosts[$maxscale_key_first], 'ipv6') {
    $ipv6_true = true
  } else {
    $ipv6_true = undef
  }

  class { '::galera::maxscale::keepalived':
    maxscale_hosts => $maxscale_hosts,
    maxscale_vip   => $maxscale_vip;
  }

  class { '::galera::firewall':
    manage_ipv6      => $ipv6_true,
    galera_hosts     => $galera_hosts,
    maxscale_hosts   => $maxscale_hosts,
    maxscale_vip     => $maxscale_vip,
    trusted_networks => $trusted_networks;
  }

  package { 'maxscale': ensure => installed; }

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

}
