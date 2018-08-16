require 'teracy-dev/util'
require 'teracy-dev/processors/processor'

module TeracyDevEssential
  module Processors
    # Display IP Address of the nodes
    class IPDisplay < TeracyDev::Processors::Processor

      def process(settings)
        ip_display_settings = {
          "default" => {}
        }
        extension_lookup_path = TeracyDev::Util.extension_lookup_path(settings, 'teracy-dev-essential')

        ip_display_settings["default"]["provisioners"] = [{
          "_id" => "essential-1",
          "type" => "shell",
          "enabled" => true,
          "name" => "ip-display",
          "path" => "#{extension_lookup_path}/teracy-dev-essential/provisioners/shell/ip_display.sh",
          "run" => "always"
        }]

        @logger.debug("ip_display_settings: #{ip_display_settings}")
        return TeracyDev::Util.override(settings, ip_display_settings)
      end
    end
  end
end
