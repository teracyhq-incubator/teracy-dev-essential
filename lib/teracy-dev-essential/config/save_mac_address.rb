require 'teracy-dev/config/configurator'
require 'teracy-dev/plugin'

module TeracyDevEssential
  module Config
    class SaveMacAddress < TeracyDev::Config::Configurator
      def configure_node(settings, config)
        @logger.debug("configure - settings: #{settings}")
        networks_settings = settings['vm']['networks']
        hostname = settings['vm']['hostname']
        node_id = settings['_id']

        configure_networks(node_id, hostname, networks_settings, config)
      end

      private
      def configure_networks(node_id, hostname, networks_settings, config)
        networks_settings ||= []
        @logger.debug("networks_settings: #{networks_settings}")
        networks_settings.each do |vm_network|
          options = {}
          network_type = vm_network['type'] || vm_network['mode']

          if network_type == 'public_network'
            network_id = vm_network['_id']
            id = "#{node_id}-#{network_type}-#{network_id}"
            options[:id] = id

            mac_file = File.join(TeracyDev::BASE_DIR, '/.vagrant/.' + id + '-public_mac_address')
            if TeracyDev::Util.boolean(vm_network['reuse_mac_address']) == true
              if File.exist?(mac_file)
                options[:mac] = File.read(mac_file).gsub(/[\s:\n]/,'')
              else
                # 08:00:27 is standard prefix for virtualbox
                mac_address = '08:00:27:' + 3.times.map { '%02x' % rand(0..255) }.join(':')
                File.write(mac_file, mac_address)
                options[:mac] = mac_address.gsub(/[\s:\n]/,'')
              end
            else
              if File.exist?(mac_file)
                FileUtils.rm mac_file
              end
            end
            config.vm.network network_type, options
          end
        end
      end
    end
  end
end
