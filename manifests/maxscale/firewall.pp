# == Class: galera_maxscale::maxscale::firewall
#
class galera_maxscale::maxscale::firewall ($peer_ip) {

  firewall {
    '200 Allow inbound multicast':
      action => accept,
      proto  => 'vrrp',
      chain  => 'INPUT',
      source => $peer_ip;
    '200 Allow outbound multicast':
      action      => accept,
      chain       => 'OUTPUT',
      proto       => 'vrrp',
      destination => '224.0.0.0/8';
  }

}
