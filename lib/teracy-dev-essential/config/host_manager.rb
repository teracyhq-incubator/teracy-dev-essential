require 'teracy-dev/config/configurator'
require 'teracy-dev/plugin'

module TeracyDevEssential
  module Config
    class HostManager < TeracyDev::Config::Configurator
      PLUGIN_NAME = "vagrant-hostmanager"

      def configure_common(settings, config)
        @plugins = settings['vagrant']['plugins'] ||= []

        plugin_aliases = get_aliases @plugins

        check_conflict_hostname plugin_aliases

        # get all eth networks or enp0s in some system version
        # then get the latest ip
        # TODO(hoatle):
        # - don't use hard-code interface names: https://github.com/teracyhq-incubator/teracy-dev-essential/issues/21
        # - select explictly by users or implictly by public > private > internal: https://github.com/teracyhq-incubator/teracy-dev-essential/issues/20
        @host_ip_command = "ip addr | grep -e eth -e enp | grep inet | cut -d/ -f1 | tail -1 | sed -e 's/^[ \t]*//' | cut -d' ' -f2"

        configure_ip_display(config, settings)

        configure_hostmanager(config) if can_proceed?(@plugins, PLUGIN_NAME)
      end

      def configure_node(settings, config)
        return if !can_proceed?(@plugins, PLUGIN_NAME)
        
        hostname = settings['vm']['hostname']

        return if hostname.nil? || hostname.empty?

        plugin_aliases = get_aliases settings['plugins']

        plugin_aliases.unshift hostname

        check_conflict_hostname plugin_aliases

        # guest hosts fixer
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

      def get_aliases plugins
        plugin = plugins.find { |p| p['name'] == PLUGIN_NAME }

        return [] if plugin.nil?

        if plugin['options'] && plugin['options']['aliases']
          plugin_aliases = plugin['options']['aliases']
        end

        plugin_aliases ||= []
      end

      def get_etc_hosts
        return @etc_hosts unless @etc_hosts.nil?

        if Vagrant::Util::Platform.windows?
          @etc_hosts = `type C:\\Windows\\System32\\drivers\\etc\\hosts`
        else
          @etc_hosts = `cat /etc/hosts`
        end

        if !$?.success?
          return nil
        end

        @etc_hosts
      end

      def check_conflict_hostname aliases
        @logger.debug('check conflict hostname')

        etc_hosts = get_etc_hosts

        if etc_hosts.nil?
          @logger.warn('Reading /etc/hosts with no success, aborted')

          return false
        end

        @logger.debug("etc_hosts: #{etc_hosts}")

        conflict_list = []
        
        hex = "[0-9a-fA-F]+"
        sign = "\.?\:?"
        ip = "#{hex}#{sign}#{hex}#{sign}#{hex}#{sign}#{hex}"
        
        aliases.each do |host|
          found = etc_hosts.scan(Regexp.new("^#{ip}.*#{host}"))

          if found and found.length > 1
            conflict_list << found.map { |x| x.to_s.gsub(/\t/, ' ') }
          end
        end

        if conflict_list.length > 0
          @logger.warn("#{conflict_list} are conflicted with each other, maybe you haven't clean the old VM setup, you can resolve this by go to the old setup repo then run: 'vagrant destroy' or 'vagrant halt && vagrant hostmanager' or you can open '/etc/hosts' and clean it manually.")
        end
      end

      def configure_ip_display(config, settings)
        extension_lookup_path = TeracyDev::Util.extension_lookup_path(settings, 'teracy-dev-essential')

        config.vm.provision "shell",
          run: "always",
          args: [@host_ip_command],
          path: "#{extension_lookup_path}/teracy-dev-essential/provisioners/shell/ip_display.sh",
          name: "Display IP"
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


      def configure_hostmanager(config)
        # conflict potential
        if TeracyDev::Plugin.installed?('vagrant-hostsupdater')
          @logger.warn('conflict potential, recommended: $ vagrant plugin uninstall vagrant-hostsupdater')
        end

        config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
          read_ip_address(vm)
        end
      end

      def read_ip_address(machine)

        result  = ""

        @logger.debug("machine.name: #{machine.name}... ")

        begin
          # sudo is needed for ifconfig
          machine.communicate.sudo(@host_ip_command) do |type, data|
            result << data if type == :stdout
          end
          @logger.debug("machine.name: #{machine.name}... success")
        rescue
          result = "# NOT-UP"
          @logger.warn("machine.name: #{machine.name}... not running")
        end

        result.strip
      end
    end
  end
end
