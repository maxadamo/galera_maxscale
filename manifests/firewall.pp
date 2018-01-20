# == Class: galera_maxscale::firewall
#
# sets firewall up
# We set inbound traffic only through the application manifest
#
class galera_maxscale::firewall (
  $manage_ipv6      = undef,
  $galera_hosts     = $::galera_maxscale::params::galera_hosts,
  $maxscale_hosts   = $::galera_maxscale::params::maxscale_hosts,
  $maxscale_vip     = $::galera_maxscale::params::maxscale_vip,
  $trusted_networks = $::galera_maxscale::params::trusted_networks
  ) inherits galera_maxscale::params {

  ['iptables', 'ip6tables'].each | String $myprovider | {
    firewall { "200 Allow outbound Galera ports (v4/v6) for ${myprovider}":
      chain    => 'OUTPUT',
      dport    => [3306, 9200],
      proto    => tcp,
      action   => accept,
      provider => $myprovider,
      before   => Exec['bootstrap_or_join'];
    }
  }

  $trusted_networks.each | String $source | {
    if ':' in $source { $provider = 'ip6tables' } else { $provider = 'iptables' }
    firewall { "200 Allow inbound Galera ports 3306, 9200 from ${source} for ${provider}":
      chain    => 'INPUT',
      source   => $source,
      dport    => [3306, 9200],
      proto    => tcp,
      action   => accept,
      provider => $provider,
      before   => Exec['bootstrap_or_join'];
    }
  }

  $galera_hosts.each | $name, $node | {
    firewall {
      default:
        dport  => [4444, 4567, 4568],
        proto  => tcp,
        action => accept,
        before => Exec['bootstrap_or_join'];
      "200 Allow outbound Galera ports ipv4 to ${name}":
        chain       => 'OUTPUT',
        destination => $node['ipv4'],
        provider    => 'iptables';
      "200 Allow inbound Galera ports ipv4 from ${name}":
        chain    => 'INPUT',
        source   => $node['ipv4'],
        provider => 'iptables';
    }
  }

  if $manage_ipv6 {
    $galera_hosts.each | $name, $node | {
      firewall {
        default:
          dport  => [4444, 4567, 4568],
          proto  => tcp,
          action => accept,
          before => Exec['bootstrap_or_join'];
        "200 Allow outbound Galera ports ipv6 to ${name}":
          chain       => 'OUTPUT',
          destination => $node['ipv6'],
          provider    => 'ip6tables';
        "200 Allow inbound Galera ports ipv6 from ${name}":
          chain    => 'INPUT',
          source   => $node['ipv6'],
          provider => 'ip6tables';
      }
    }
  }

  # MaxScale rules: let's open all the ports across Keepalived hosts
  $maxscale_cluster = deep_merge($maxscale_hosts, $maxscale_vip)
  $maxscale_cluster.each | $name, $node | {
    firewall {
      default:
        action => accept,
        proto  => tcp,
        dport  => '1-65535',
        before => Exec['bootstrap_or_join'];
      "200 Allow inbound tcp ipv4 from ${name}":
        chain    => 'INPUT',
        source   => $node['ipv4'],
        provider => 'iptables';
      "200 Allow outbound tcp ipv4 to ${name}":
        chain       => 'OUTPUT',
        destination => $node['ipv4'],
        provider    => 'iptables';
      "200 Allow inbound udp ipv4 to ${name}":
        chain    => 'INPUT',
        source   => $node['ipv4'],
        proto    => udp,
        provider => 'iptables';
      "200 Allow outbound udp ipv4 from ${name}":
        chain       => 'OUTPUT',
        destination => $node['ipv4'],
        proto       => udp,
        provider    => 'iptables';
    }
  }

  if $manage_ipv6 {
    $maxscale_cluster.each | $name, $node | {
      firewall {
        default:
          action => accept,
          proto  => tcp,
          dport  => '1-65535',
          before => Exec['bootstrap_or_join'];
        "200 Allow inbound tcp ipv6 from ${name}":
          chain    => 'INPUT',
          source   => $node['ipv6'],
          provider => 'ip6tables';
        "200 Allow outbound tcp ipv6 to ${name}":
          chain       => 'OUTPUT',
          destination => $node['ipv6'],
          provider    => 'ip6tables';
        "200 Allow inbound udp ipv6 from ${name}":
          chain    => 'INPUT',
          source   => $node['ipv6'],
          proto    => udp,
          provider => 'ip6tables';
        "200 Allow outbound udp ipv6 to ${name}":
          chain       => 'OUTPUT',
          destination => $node['ipv6'],
          proto       => udp,
          provider    => 'ip6tables';
      }
    }
  }

}
