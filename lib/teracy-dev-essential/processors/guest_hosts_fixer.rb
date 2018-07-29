require 'teracy-dev/processors/processor'

module TeracyDevEssential
  module Processors
    # fix hosts file on the guest machine
    # see: https://github.com/devopsgroup-io/vagrant-hostmanager/issues/203
    # NOTE: seems that there's bug with 2nd machine on 2 machines setup
    class GuestHostsFixer < TeracyDev::Processors::Processor

      def process(settings)
        @logger.debug("process - settings: #{settings}")
        # interate over each nodes and add provisioner
        nodes = settings['nodes'] ||= []

        nodes.each do |node|
          @logger.debug("process - node: #{node}")
          if node['vm']['hostname']
            fix_hosts_command = "sed -i \"s/\\(127.0.1.1\\)\\(.*\\)#{node['vm']['hostname']}\\(.*\\)/\\1\\3/\" /etc/hosts"
            @logger.debug("process - fix_hosts_command: #{fix_hosts_command}")
            node['provisioners'] << {
              "_id" => "essential-0",
              "type" => "shell",
              "name" => "guest-hosts-fixer",
              "enabled" => true,
              "inline" => fix_hosts_command
            }
          end
        end
        settings
      end
    end
  end
end
