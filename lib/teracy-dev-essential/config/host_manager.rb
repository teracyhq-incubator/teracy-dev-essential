require 'teracy-dev/config/configurator'
require 'teracy-dev/plugin'
require 'pp'

module TeracyDevEssential
  module Config
    class HostManager < TeracyDev::Config::Configurator
      PLUGIN_NAME = "vagrant-hostmanager"

      def configure_common(settings, config)
        @plugins = settings['vagrant']['plugins'] ||= []

        host_ip_index = configure_ip_display(config, settings)

        configure_hostmanager(config, host_ip_index) if can_proceed?(@plugins, PLUGIN_NAME)
      end

      def configure_node(settings, config)
        return if !can_proceed?(@plugins, PLUGIN_NAME)
        # guest hosts fixer
        hostname = settings['vm']['hostname']
        return if hostname.nil? || hostname.empty?
        fix_hosts_command = "sed -i \"s/\\(127.0.1.1\\)\\(.*\\)#{hostname}\\(.*\\)/\\1\\3/\" /etc/hosts"
        @logger.debug("fix_hosts_command: #{fix_hosts_command}")

        options = {
          "inline" => fix_hosts_command
        }

        config.vm.provision "guest-hosts-fixer", type: "shell" do |provision|
          provision.set_options(options)
        end

      end

      private

      def configure_ip_display(config, settings)
        extension_lookup_path = TeracyDev::Util.extension_lookup_path(settings, 'teracy-dev-essential')

        networks = get_all_configured_networks(settings)

        # default VM network (127.0.0.1) is at 0 index
        # we use the latest defined network IP
        host_ip_index = networks.length

        # if there are no networks defined
        # init a default private network with dynamic ip
        if host_ip_index == 0
          config.vm.network "private_network", type: "dhcp"

          host_ip_index = 1
        end

        config.vm.provision "shell",
          run: "always",
          args: [host_ip_index],
          path: "#{extension_lookup_path}/teracy-dev-essential/provisioners/shell/ip_display.sh",
          name: "Display IP"

        host_ip_index
      end

      def get_all_configured_networks(settings)
        networks = []

        settings['nodes'].each do |node|
          networks = node['vm']['networks'].each do |network|
            networks << network
          end if node['vm']['networks']
        end

        @logger.debug("networks #{pp(networks)}")

        networks
      end

      # check if plugin is installed and enabled to proceed
      def can_proceed?(plugins, plugin_name)
          plugins = plugins.select do |plugin|
            plugin['name'] == plugin_name
          end

          return false if plugins.length != 1
          plugin = plugins[0]

          if !TeracyDev::Plugin.installed?(plugin_name)
            @logger.debug("#{plugin_name} is not installed")
            return false
          end

          if plugin['enabled'] != true
            @logger.debug("#{plugin_name} is installed but not enabled so its settings is ignored")
            return false
          end
          return true
      end


      def configure_hostmanager(config, host_ip_index)
        # conflict potential
        if TeracyDev::Plugin.installed?('vagrant-hostsupdater')
          @logger.warn('conflict potential, recommended: $ vagrant plugin uninstall vagrant-hostsupdater')
        end

        config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
          read_ip_address(vm, host_ip_index)
        end
      end

      # thanks to https://github.com/devopsgroup-io/vagrant-hostmanager/issues/121#issuecomment-69050265
      def read_ip_address(machine, host_ip_index)
        # command = "LANG=en ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1 }'"
        command = "hostname -I  | cut -d ' ' -f #{host_ip_index+1}"

        result  = ""

        @logger.debug("_read_ip_address: #{machine.name}... ")

        begin
          # sudo is needed for ifconfig
          machine.communicate.sudo(command) do |type, data|
            result << data if type == :stdout
          end
          @logger.debug("_read_ip_address: #{machine.name}... success")
        rescue
          result = "# NOT-UP"
          @logger.warn("_read_ip_address: #{machine.name}... not running")
        end

        result.strip
      end
    end
  end
end
