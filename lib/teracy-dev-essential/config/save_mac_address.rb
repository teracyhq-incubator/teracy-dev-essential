require 'teracy-dev/config/configurator'
require 'teracy-dev/plugin'

module TeracyDevEssential
  module Config
    class SaveMacAddress < TeracyDev::Config::Configurator
      def configure(settings, config, type:)
        return
        case type
        when 'common'
          @logger.debug("configure - settings: #{settings}")
        when 'node'
          @logger.debug("configure - settings: #{settings}")
        end
      end
    end
  end
end
