require 'teracy-dev/config/configurator'
require 'teracy-dev/plugin'

module TeracyDevEssential
  module Config
    class HostManager < TeracyDev::Config::Configurator
      PLUGIN_NAME = "vagrant-hostmanager"

      def configure_common(settings, config)
        @plugins = settings['vagrant']['plugins'] ||= []
        configure_hostmanager(config) if can_proceed?(@plugins, PLUGIN_NAME)
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

      # check if plugin is installed and enabled to proceed
      def can_proceed?(plugins, plugin_name)

          plugins = plugins.select do |plugin|
            plugin['name'] == plugin_name
          end

          return false if plugins.length != 1
          plugin = plugins[0]

          if !TeracyDev::Plugin.installed?(plugin_name)
            @logger.warn("#{plugin_name} is not installed")
            return false
          end

          if plugin['enabled'] != true
            @logger.info("#{plugin_name} is installed but not enabled so its settings is ignored")
            return false
          end
          return true
      end


      def configure_hostmanager(config)
        # conflict potential
        if TeracyDev::Plugin.installed?('vagrant-hostsupdater')
          @logger.warn('conflict potential, recommended: $ vagrant plugin uninstall vagrant-hostsupdater')
        end

        # workaround for :public_network
        # maybe this will not work with :private_network
        config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
          #FIXME: make this work with different network settings instead
          read_ip_address(vm)
        end
      end


      # thanks to https://github.com/devopsgroup-io/vagrant-hostmanager/issues/121#issuecomment-69050265
      def read_ip_address(machine)
        command = "LANG=en ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1 }'"
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
        # the second inet is more accurate
        result.chomp.split("\n").last
      end
    end
  end
end
