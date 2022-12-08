# frozen_string_literal: true

require 'spec_helper'

describe 'anycast_services' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
          :networking => {
            'ip' => '10.2.1.44',
            'primary' => 'ens192'
          }
        })
      end
      let(:node) { 'dnssrv1.example.com' }

      context 'with defaults' do
        let(:params) do
          {
            'zebra_anycast_addresses' => [
              '10.240.0.10/32',
              '10.240.1.10/32',
            ],
            'ospfd_anycast_networks' => [
              {
                'address' => '10.2.1.0/24',
                'area' => '0.0.0.0',
              },
              {
                'address' => '10.240.0.10/32',
                'area' => '0.0.0.0',
              },
              {
                'address' => '10.240.1.10/32',
                'area' => '0.0.0.0',
              },
            ],
          }
        end

        it { is_expected.to compile }
        it {
          is_expected.to contain_package('quagga')
            .with_ensure('present')
        }
        it {
          is_expected.to contain_sysctl__value('net.ipv4.ip_forward')
            .with_value('1')
        }
        it {
          is_expected.to contain_file('/var/log/quagga')
            .with_ensure('directory')
            .with_owner('quagga')
            .with_group('quagga')
            .that_requires('Package[quagga]')
            .that_requires('Sysctl::Value[net.ipv4.ip_forward]')
        }
        it {
          is_expected.to contain_file('/etc/quagga/ospfd.conf')
          .with_ensure('file')
            .that_requires('Package[quagga]')
            .that_requires('Sysctl::Value[net.ipv4.ip_forward]')
            # .with_content(%r{\n ospf router-id 10.2.1.44\n})
        }
        it {
          is_expected.to contain_file('/etc/quagga/vtysh.conf')
            .that_requires('Package[quagga]')
            .that_requires('Sysctl::Value[net.ipv4.ip_forward]')
        }
        it {
          is_expected.to contain_file('/etc/quagga/zebra.conf')
            .that_requires('Package[quagga]')
            .that_requires('Sysctl::Value[net.ipv4.ip_forward]')
            # .with_content(%r{\n ospf router-id 10.2.1.44\n})
        }
        it {
          is_expected.to contain_service('ospfd.service')
            .with_ensure('running')
            .with_enable(true)
            .that_requires('File[/etc/quagga/ospfd.conf]')
            .that_subscribes_to('File[/etc/quagga/ospfd.conf]')
        }
        it {
          is_expected.to contain_service('zebra.service')
            .with_ensure('running')
            .with_enable(true)
            .that_requires('File[/etc/quagga/zebra.conf]')
            .that_subscribes_to('File[/etc/quagga/zebra.conf]')
        }
        it {
          is_expected.to contain_class('supervisord')
            .with_service_ensure('stopped')
            .with_service_enable(false)
            .with_package_ensure('absent')
        }
        it { is_expected.not_to contain_file('/opt/dns_ospf_check.sh') }
        it { is_expected.not_to contain_supervisord__program('dns_ospf_check') }
      end

      context 'dns checks enabled' do
        let(:params) do
          {
            'enable_dns_ospf_checks' => true,
            'zebra_anycast_addresses' => [
              '10.240.0.10/32',
              '10.240.1.10/32',
            ],
            'ospfd_anycast_networks' => [
              {
                'address' => '10.2.1.0/24',
                'area' => '0.0.0.0',
              },
              {
                'address' => '10.240.0.10/32',
                'area' => '0.0.0.0',
              },
              {
                'address' => '10.240.1.10/32',
                'area' => '0.0.0.0',
              },
            ],
          }
        end
        it { is_expected.to contain_class('supervisord') }
        it {
          is_expected.to contain_file('/opt/dns_ospf_check.sh')
            .with_content(%r{\n      ip addr add 10.240.0.10/32 dev lo\n})
        }
        it { is_expected.to contain_supervisord__program('dns_ospf_check') }
      end
    end
  end
end
