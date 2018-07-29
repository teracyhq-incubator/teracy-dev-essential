require 'teracy-dev/processors/processor'

module TeracyDevEssential
  module Processors
    # Display IP Address of the nodes
    class IPDisplay < TeracyDev::Processors::Processor

      def process(settings)
        nodes = settings['nodes'] ||= []

        nodes.each do |node|
          @logger.debug("process - node: #{node}")
          node['provisioners'] << {
            "_id" => "essential-1",
            "type" => "shell",
            "enabled" => true,
            "name" => "ip-display",
            "path" => "workspace/teracy-dev-essential/provisioners/shell/ip_display.sh",
            "run" => "always"
          }
        end
        settings
      end
    end
  end
end
