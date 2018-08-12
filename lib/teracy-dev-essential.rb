require 'teracy-dev'

require_relative 'teracy-dev-essential/config/host_manager'
require_relative 'teracy-dev-essential/config/save_mac_address'
require_relative 'teracy-dev-essential/processors/guest_hosts_fixer'
require_relative 'teracy-dev-essential/processors/ip_display'

module TeracyDevEssential

  def self.init
    TeracyDev.register_processor(Processors::GuestHostsFixer.new)
    TeracyDev.register_processor(Processors::IPDisplay.new)


    TeracyDev.register_configurator(Config::HostManager.new)
    TeracyDev.register_configurator(Config::SaveMacAddress.new)
  end

end
