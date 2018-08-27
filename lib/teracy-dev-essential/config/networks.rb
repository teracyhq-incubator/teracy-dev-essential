require 'teracy-dev/config/configurator'
require 'teracy-dev/util'

module TeracyDevEssential
  module Config
    # see: https://www.vagrantup.com/docs/networking/
    class Networks < TeracyDev::Config::Configurator

      def configure_node(settings, config)
        networks_settings = settings['vm']['networks']
        configure_networks(settings['_id'], networks_settings, config)
      end

      private

      def configure_networks(node_id, networks_settings, config)
        networks_settings ||= []
        @logger.debug("configure_networks: #{networks_settings}")
        networks_settings.each do |vm_network|
          network_type = vm_network['type'] || vm_network['mode']
          # auto select default bridge for public_network when 'bridge' option is not specified
          if network_type == 'public_network' and !TeracyDev::Util.exist? vm_network['bridge']

            network_id = vm_network['_id']
            # convention, follow: https://github.com/teracyhq-incubator/teracy-dev-core/issues/10
            id = "#{node_id}-#{network_type}-#{network_id}"

            @logger.debug("configure_networks: auto select default bridge for #{vm_network} with id: #{id}")
            bridge_interface = get_default_nic()
            @logger.debug("configure_networks: bridge_interface: #{bridge_interface}")
            if TeracyDev::Util.exist? bridge_interface
              options = {
                id: id,
                bridge: bridge_interface
              }
              config.vm.network network_type, options
              # see:
              # - https://github.com/hashicorp/vagrant/blob/v2.1.2/plugins/kernel_v2/config/vm.rb#L572
              # - https://github.com/hashicorp/vagrant/blob/v2.1.2/plugins/kernel_v2/config/vm.rb#L249
              @logger.debug("config.vm.networks: #{config.vm.networks}")
            end
          end
        end
      end


      def get_default_nic()
        default_interface = ""
        if Vagrant::Util::Platform.windows?
            default_interface = %x[wmic.exe nic where "NetConnectionStatus=2" get NetConnectionID | more +1]
            default_interface = default_interface.strip
        elsif Vagrant::Util::Platform.linux?
            default_interface = %x[route | grep '^default' | grep -o '[^ ]*$']
            default_interface = default_interface.strip
        elsif Vagrant::Util::Platform.darwin?
            nicName = %x[route -n get 8.8.8.8 | grep interface | awk '{print $2}']
            default_interface = nicName.strip
            nicString = %x[networksetup -listnetworkserviceorder | grep 'Hardware Port' | grep #{default_interface} | awk -F'[:,]' '{print $2}']
            extension = nicString.strip == "Wi-Fi" ? " (AirPort)" : ""
            default_interface = default_interface + ': ' + nicString.strip + extension
        end
        return default_interface
      end
    end
  end
end
