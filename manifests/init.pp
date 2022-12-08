# @summary Manage Quagga associated OSPF setup for anycast services
#
# Manage Quagga associated OSPF setup for anycast services such as DNS and RADIUS.
#
# @param zebra_anycast_addresses
#   Addresses to be advertised via anycast.
#
# @param ospfd_anycast_networks
#   An array of hashes that contain the network CIDR and the OSPF area.
#   Each entry in the array represents a `network` line in ospfd.conf within the `router ospf` section.
#
# @param ospfd_interfaces
#   Interfaces to use with OSPF.
#
# @param zebra_interfaces
#   Interfaces to use with Zebra.
#
# @param enable_dns_ospf_checks
#   Use a script managed by supervisord to add or remove the anycast addresses from the lo interface
#   based on if DNS is working or not.
#
# @param enable_radius_ospf_checks
#   Use a script managed by supervisord to add or remove the anycast addresses from the lo interface
#   based on if FreeRADIUS is up or not.
#
# @param ospfd_log_adjacency_changes
#   Determines if the `log-adjacency-changes` directive is added to the `router ospf` section.
#
# @param ospfd_auto_cost_reference_bandwidth
#   The value use to determine route cost. Note that it is important to ensure reference bandwidth
#   is consistent across all routers and/or hosts.
#
# @param ospf_area_authentications
#   An optional hash where the key is the area and the value is the authentication mechanism.
#
# @param ospfd_password
#   The value for `password` in ospfd.conf
#
# @param zebra_enable_password
#   The value for `enable password` in zebra.conf
#
# @param zebra_password
#   The value for `password` in zebra.conf
#
# @param quagga_log_directory
#   The directory that will contain logs from zebra and ospfd
#
# @param ospfd_router_id
#   The router id for ospfd in IPv4 format
#
# @param zebra_router_id
#   The router id for zebra in IPv4 format
#
# @param ospfd_hostname
#   The value for `hostname` in opsfd.conf
#
# @param ospfd_log_file
#   The file for ospfd to log to. This file will be placed in the directory specified in `quagga_log_directory`
#
# @param zebra_hostname
#   The value for `hostname` in zebra.conf
#
# @param zebra_log_file
#   The file for zebra to log to. This file will be placed in the directory specified in `quagga_log_directory`
#
# @example Advertise two anycast addresses
#   class { 'anycast_services':
#     zebra_anycast_addresses => [
#       '10.240.0.10/32',
#       '10.240.1.10/32',
#     ],
#     ospfd_anycast_networks  => [
#       {
#         'address' => '10.2.1.0/24',
#         'area'    => '0.0.0.0',
#       },
#       {
#         'address' => '10.240.0.10/32',
#         'area'    => '0.0.0.0',
#       },
#       {
#         'address' => '10.240.1.10/32',
#         'area'    => '0.0.0.0',
#       },
#     ],
#   }
#
class anycast_services (
  Array[Anycast_services::CIDR] $zebra_anycast_addresses,
  Array[Hash[String[1], Stdlib::IP::Address::V4]] $ospfd_anycast_networks,

  Array $ospfd_interfaces = ['lo', $facts['networking']['primary']],
  Array $zebra_interfaces = ['lo', $facts['networking']['primary']],
  Boolean $enable_dns_ospf_checks = false,
  Boolean $enable_radius_ospf_checks = false,
  Boolean $ospfd_log_adjacency_changes = true,
  Integer $ospfd_auto_cost_reference_bandwidth = 1000,
  Optional[Hash[Stdlib::IP::Address::V4::Nosubnet, String[1]]] $ospf_area_authentications = undef,
  Sensitive[String[1]] $ospfd_password = Sensitive('zebra'),
  Sensitive[String[1]] $zebra_enable_password = Sensitive('zebra'),
  Sensitive[String[1]] $zebra_password = Sensitive('zebra'),
  Stdlib::Absolutepath $quagga_log_directory = '/var/log/quagga',
  Stdlib::IP::Address::V4::Nosubnet $ospfd_router_id = $facts['networking']['ip'],
  Stdlib::IP::Address::V4::Nosubnet $zebra_router_id = $facts['networking']['ip'],
  String[1] $ospfd_hostname = $facts['networking']['hostname'],
  String[1] $ospfd_log_file = 'ospfd.log',
  String[1] $zebra_hostname = $facts['networking']['hostname'],
  String[1] $zebra_log_file = 'zebra.log',
) {
  # log rotation?
  package { 'quagga':
    ensure => present,
  }

  sysctl::value { 'net.ipv4.ip_forward':
    value => '1',
  }

  file {
    default:
      require => [
        Package['quagga'],
        Sysctl::Value['net.ipv4.ip_forward'],
      ],
      ;
    $quagga_log_directory:
      ensure => directory,
      owner  => 'quagga',
      group  => 'quagga',
      ;
    '/etc/quagga/ospfd.conf':
      ensure  => file,
      content => epp('anycast_services/ospfd.conf.epp',
        {
          'ospfd_anycast_networks'              => $ospfd_anycast_networks,
          'ospfd_auto_cost_reference_bandwidth' => $ospfd_auto_cost_reference_bandwidth,
          'ospfd_hostname'                      => $ospfd_hostname,
          'ospfd_interfaces'                    => $ospfd_interfaces,
          'ospfd_log_adjacency_changes'         => $ospfd_log_adjacency_changes,
          'ospfd_log_file'                      => $ospfd_log_file,
          'ospfd_password'                      => $ospfd_password,
          'ospfd_router_id'                     => $ospfd_router_id,
          'quagga_log_directory'                => $quagga_log_directory,
        }
      ),
      ;
    '/etc/quagga/vtysh.conf':
      ensure => file,
      ;
    '/etc/quagga/zebra.conf':
      ensure  => file,
      content => epp('anycast_services/zebra.conf.epp',
        {
          'quagga_log_directory'    => $quagga_log_directory,
          'zebra_anycast_addresses' => $zebra_anycast_addresses,
          'zebra_enable_password'   => $zebra_enable_password,
          'zebra_hostname'          => $zebra_hostname,
          'zebra_interfaces'        => $zebra_interfaces,
          'zebra_log_file'          => $zebra_log_file,
          'zebra_password'          => $zebra_password,
          'zebra_router_id'         => $zebra_router_id,
        }
      ),
      ;
  }

  service {
    default:
      ensure => running,
      enable => true,
      ;
    'ospfd.service':
      require   => File['/etc/quagga/ospfd.conf'],
      subscribe => File['/etc/quagga/ospfd.conf'],
      ;
    'zebra.service':
      require   => File['/etc/quagga/zebra.conf'],
      subscribe => File['/etc/quagga/zebra.conf'],
  }

  unless $enable_dns_ospf_checks or $enable_radius_ospf_checks {
    class { 'supervisord':
      service_ensure => stopped,
      service_enable => false,
      package_ensure => absent,
    }
  }

  if $enable_dns_ospf_checks {
    include supervisord

    file { '/opt/dns_ospf_check.sh':
      ensure  => file,
      mode    => '0744',
      owner   => 'root',
      content => epp('anycast_services/supervisord/dns_ospf_check.sh.epp',
        {
          'zebra_anycast_addresses' => $zebra_anycast_addresses,
        }
      ),
      notify  => Service[$supervisord::service_name],
    }

    supervisord::program { 'dns_ospf_check':
      command     => '/opt/dns_ospf_check.sh',
      priority    => '100',
      autorestart => true,
      autostart   => true,
      user        => 'root',
      require     => File['/opt/dns_ospf_check.sh'],
    }
  } else {
    file { '/opt/dns_ospf_check.sh':
      ensure => absent,
    }
  }

  if $enable_radius_ospf_checks {
    include supervisord

    file { '/opt/radius_ospf_check.sh':
      ensure  => file,
      mode    => '0744',
      owner   => 'root',
      content => epp('anycast_services/supervisord/radius_ospf_check.sh.epp',
        {
          'zebra_anycast_addresses' => $zebra_anycast_addresses,
        }
      ),
      notify  => Service[$supervisord::service_name],
    }

    supervisord::program { 'radius_ospf_check':
      command     => '/opt/radius_ospf_check.sh',
      priority    => '100',
      autorestart => true,
      autostart   => true,
      user        => 'root',
      require     => File['/opt/radius_ospf_check.sh'],
    }
  } else {
    file { '/opt/radius_ospf_check.sh':
      ensure => absent,
    }
  }
}
