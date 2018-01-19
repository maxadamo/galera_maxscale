# == Class: galera_maxscale::maxscale::maxscale
#
class galera_maxscale::maxscale::maxscale (
  $galera_hosts      = $::galera_maxscale::params::galera_hosts,
  $maxscale_hosts    = $::galera_maxscale::params::maxscale_hosts,
  $maxscale_vip      = $::galera_maxscale::params::maxscale_vip,
  $maxscale_password = $::galera_maxscale::params::maxscale_password,
  $trusted_networks  = $::galera_maxscale::params::trusted_networks
  ) inherits galera_maxscale::params {

  $maxscale_key_first = inline_template('<% @maxscale_hosts.each_with_index do |(key, value), index| %><% if index == 0 %><%= key %><% end -%><% end -%>')
  $vip_key = inline_template('<% @maxscale_vip.each do |key, value| %><%= key %><% end -%>')
  $vip_ip = $maxscale_vip[$vip_key]['ipv4']
  if has_key($maxscale_hosts[$maxscale_key_first], 'ipv6') {
    $ipv6_true = true
  } else {
    $ipv6_true = undef
  }

  class { '::galera_maxscale::maxscale::keepalived':
    maxscale_hosts => $maxscale_hosts,
    maxscale_vip   => $maxscale_vip;
  }

  class { '::galera_maxscale::firewall':
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
