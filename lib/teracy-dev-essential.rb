require 'teracy-dev'

require_relative 'teracy-dev-essential/config/host_manager'
require_relative 'teracy-dev-essential/config/save_mac_address'
require_relative 'teracy-dev-essential/config/networks'
require_relative 'teracy-dev-essential/config/rsync_recovery'

module TeracyDevEssential

  def self.init
    TeracyDev.register_configurator(Config::HostManager.new)
    TeracyDev.register_configurator(Config::SaveMacAddress.new)
    TeracyDev.register_configurator(Config::Networks.new)
    TeracyDev.register_configurator(Config::RsyncRecovery.new)
  end

end
