# == Class: galera_maxscale::maxscale::keepalived
#
class galera_maxscale::maxscale::keepalived (
  $maxscale_hosts    = $::galera_maxscale::params::maxscale_hosts,
  $maxscale_vip      = $::galera_maxscale::params::maxscale_vip,
  $network_interface = $::galera_maxscale::params::network_interface,
  $manage_ipv6       = undef
  ) inherits galera_maxscale::params {

  $vip_key = inline_template('<% @maxscale_vip.each do |key, value| %><%= key %><% end -%>')
  $maxscale_key_first = inline_template('<% @maxscale_hosts.each_with_index do |(key, value), index| %><% if index == 0 %><%= key %><% end -%><% end -%>')
  $maxscale_key_second = inline_template('<% @maxscale_hosts.each_with_index do |(key, value), index| %><% if index == 1 %><%= key %><% end -%><% end -%>')
  $peer_ip = $::fqdn ? {
    $maxscale_key_first  => $maxscale_hosts[$maxscale_key_second]['ipv4'],
    $maxscale_key_second => $maxscale_hosts[$maxscale_key_first]['ipv4'],
  }

  include ::keepalived
  class { '::galera_maxscale::maxscale::firewall': peer_ip => $peer_ip; }

  keepalived::vrrp::script { 'check_maxscale':
    script   => 'killall -0 maxscale',
    interval => '2',
    weight   => '2';
  }

  if ($manage_ipv6) {
    keepalived::vrrp::instance { 'MaxScale':
      interface                  => $network_interface,
      state                      => 'BACKUP',
      virtual_router_id          => '50',
      unicast_source_ip          => $::ipaddress,
      unicast_peers              => [$peer_ip],
      priority                   => '100',
      auth_type                  => 'PASS',
      auth_pass                  => 'secret',
      virtual_ipaddress          => "${maxscale_vip[$vip_key]['ipv4']}/${maxscale_vip[$vip_key]['ipv4_subnet']}",
      virtual_ipaddress_excluded => ["${maxscale_vip[$vip_key]['ipv6']}/${maxscale_vip[$vip_key]['ipv6_subnet']}"],
      track_script               => 'check_maxscale';
    }
  } else {
    keepalived::vrrp::instance { 'MaxScale':
      interface         => $network_interface,
      state             => 'BACKUP',
      virtual_router_id => '50',
      unicast_source_ip => $::ipaddress,
      unicast_peers     => [$peer_ip],
      priority          => '100',
      auth_type         => 'PASS',
      auth_pass         => 'secret',
      virtual_ipaddress => "${maxscale_vip[$vip_key]['ipv4']}/${maxscale_vip[$vip_key]['ipv4_subnet']}",
      track_script      => 'check_maxscale';
    }
  }


}
