lib_dir = File.expand_path('./lib', __dir__)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)


require 'teracy-dev'
require 'teracy-dev-essential'

TeracyDev.register_processor(TeracyDevEssential::Processors::GuestHostsFixer.new)
TeracyDev.register_processor(TeracyDevEssential::Processors::IPDisplay.new)


TeracyDev.register_configurator(TeracyDevEssential::Config::HostManager.new)
TeracyDev.register_configurator(TeracyDevEssential::Config::SaveMacAddress.new)
