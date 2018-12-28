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

        # Get all system networks then get the latest ip:
        # 1. Get network interface names: ls -la /sys/class/net/
        # - if not present then fallback to default net name: eth enp
        # 2. Process net name: eth0 eth1 -> eth0 -e eth1
        # 3. Get ip address: ip addr | grep -e eth0 -e eth1
        # 4. Get all inet, then filter IP: grep inet | cut -d/ -f1 | sed -e 's/^[ \t]*//' | cut -d' ' -f2
        @get_ip_list = "net_name=`ls -la /sys/class/net/ | grep -v virtual | grep -o '/net/.*' | cut -d/ -f3`; if [[ -z $net_name ]]; then net_name='eth enp'; fi; net_name_processed=`echo $net_name | sed -e 's/ / \-e /g'`; ip_address_list=`ip addr | grep -e $net_name_processed | grep inet | cut -d/ -f1 | sed -e 's/^[ \t]*//' | cut -d' ' -f2`;"


        # 5. Get IP list and its length: ip_address_length=${#ip_address_arr[@]}
        # 6. Get IP address at specified index: echo $ip_address_list | cut -d' ' -f ${PRIMARY_NETWORK_INDEX:-$ip_address_length}
        # - fallback to IP length if index is not specified
        @host_ip_display_command = "#{@get_ip_list} ip_address_arr=($ip_address_list); ip_address_length=${#ip_address_arr[@]}; ip_address=`echo $ip_address_list | cut -d' ' -f ${PRIMARY_NETWORK_INDEX:-$ip_address_length}`; echo $1 $ip_address;"

        @host_ip_list_display_command = "#{@get_ip_list} echo $ip_address_list;"

        # store ip index for each nodes
        @host_ip_index = {}

        configure_hostmanager(config) if can_proceed?(@plugins, PLUGIN_NAME)
      end

      def configure_node(settings, config)
        configure_ip_display(config, settings)

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
          found = etc_hosts.scan(Regexp.new("^#{ip}.*[\s\t]#{host}"))

          if found and found.length > 1

            conflicted_list = {}

            found.map do |x|
              line = x.to_s.gsub(/\t/, ' ')

              conflicted_list[line.split(' ')[0]] = host
            end

            found = conflicted_list.map do |key, value|
                "#{key}  #{value}"
            end

            conflict_list << found if found.length > 1
          end
        end

        if conflict_list.length > 0
          @logger.warn("#{conflict_list} are conflicted with each other,"\
            " maybe you haven't clean the old VM setup, you can resolve this by go to the old setup"\
            " repo then run: 'vagrant destroy' or 'vagrant halt && vagrant hostmanager' or you can"\
            " open '/etc/hosts' and clean it manually.")
        end
      end

      # Set `primary: true` to priority this network, example:
      #  {
      #     ...
      #     networks:
      #       - _id: "0"
      #         type: "public_network"
      #       - _id: "1"
      #         type: "private_network"
      #         primary: true # <-- priority this over public_network
      #       ...
      #  }
      # Otherwise it will follow this order: public_network > private_network
      def configure_ip_display(config, settings)
        networks = settings['vm']['networks'] || []

        machine_name = settings['name']

        @logger.debug("machine_name: #{machine_name}")

        # prefer primary network
        primary_network = networks.find { |net| TeracyDev::Util.true? net['primary'] }


        # or prefer network by order: public > private
        ['public_network', 'private_network'].each do |network|
          primary_network = networks.find { |net| net['type'] == network }

          break if !primary_network.nil?
        end if primary_network.nil?

        primary_network_index = -1

        if !primary_network.nil?
          primary_network_index = networks.index primary_network
        end

        @logger.debug("primary_network #{primary_network_index}: #{primary_network}")

        @host_ip_index[machine_name] = primary_network_index

        config.vm.provision "shell",
          run: "always",
          env: {
            # with ip default at 1 so +1, shell cmd `cut -f` at 1 so +1, total: 2
            'PRIMARY_NETWORK_INDEX': primary_network_index + 2
          },
          args: ['IP Address: '],
          inline: @host_ip_display_command,
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
          machine.communicate.sudo(@host_ip_list_display_command) do |type, data|
            result << data if type == :stdout
          end

          host_ip_index = @host_ip_index[machine.name.to_s]

          # default index at 0, so + 1
          result = result.split(' ')[host_ip_index + 1]

          @logger.debug("result for #{machine.name} at index #{@host_ip_index[machine.name.to_s]}: #{result}")

          @logger.debug("machine.name: #{machine.name}... success")
        rescue
          result = "# NOT-UP"
          @logger.warn("machine.name: #{machine.name}... not running")
        end

        @logger.debug("result: #{result}")

        result.strip
      end
    end
  end
end
