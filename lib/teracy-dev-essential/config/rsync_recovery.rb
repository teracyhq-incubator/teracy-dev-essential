require 'teracy-dev/config/configurator'
require 'teracy-dev/plugin'
require 'teracy-dev/util'

class NonZeroExit < StandardError
end

module TeracyDevEssential
  module Config
    class RsyncRecovery < TeracyDev::Config::Configurator

      def configure_common(settings, config)

        return if !gatling_rsync_installed?

        plugins = settings['vagrant']['plugins'] ||= []

        valid_command(plugins)

        config.gatling.rsync_on_startup = false

        @vagrant_version = Vagrant::VERSION

        unless TeracyDev::Util.require_version_valid?(@vagrant_version, ">= 2.2.0")
          @logger.warn("vagrant current version: #{@vagrant_version}")
          @logger.warn("rsync auto recovery is only supported by vagrant version `>= 2.2.0`, please upgrade vagrant")
          return
        end

        return unless can_proceed?(plugins)

        # check rsync exist and correct config
        return unless rsync?(settings)

        @last_node = settings['nodes'].last['name']

      end

      def configure_node(settings, config)
        return if settings['name'] != @last_node

        @cmd = 'gatling-rsync-auto'

        if Vagrant::Util::Platform.linux?
          if TeracyDev::Util.require_version_valid?(@vagrant_version, ">= 2.2.3")
            @cmd = 'rsync-auto'

          else
            @logger.warn("a bug related to syncing created files will be fixed by vagrant >= 2.2.3, please upgrade vagrant")
          end
        end

        configure_trigger_after(config)
      end

      private

      # check if plugin is installed and enabled to proceed
      def can_proceed?(plugins)
        return false if plugins.empty?

        plugin = plugins.select { |item| item['name'] == 'vagrant-gatling-rsync' and TeracyDev::Util.true? item['enabled'] }.first

        if plugin
          rsync_on_startup = plugin['options']['rsync_on_startup']

          unless TeracyDev::Util.exist? rsync_on_startup
            rsync_on_startup = true
          end

          return true if TeracyDev::Util.true?(rsync_on_startup)
        end

        return false
      end

      def gatling_rsync_installed?
        return TeracyDev::Plugin.installed?('vagrant-gatling-rsync')
      end

      def rsync?(settings)
        rsync = {}

        settings['nodes'].map do |item|
          sync_settings = item['vm']['synced_folders']

          next if sync_settings.nil?
          next if sync_settings.empty?

          if rsync_valid?(sync_settings)
            rsync[item['name']] = sync_settings
          end
        end

        return true unless rsync.empty?

        return false
      end

      # check rsync have correct config
      def rsync_valid?(sync_settings)
        rsync_exist = sync_settings.find { |x| x['type'] == 'rsync' }

        if rsync_exist
          return true if TeracyDev::Util.exist?(rsync_exist['host']) and TeracyDev::Util.exist?(rsync_exist['guest'])
        end

        return false
      end

      # check if run gatling-rsync-auto command
      def valid_command(plugins)
        gatling_cmd = ARGV.any? { |s| s.include?('gatling-rsync-auto') }

        if gatling_cmd
          gatling_plugin_enabled = plugins.select { |item| item['name'] == 'vagrant-gatling-rsync' and TeracyDev::Util.true? item['enabled'] }

          if gatling_plugin_enabled.empty?
            @logger.error("vagrant-gatling-rsync plugin must be enabled, and use 'vagrant up' instead of 'vagrant gatling-rsync-auto'")
            abort
          else
            @logger.warn("'vagrant gatling-rsync-auto' does support rsync recovery, will use 'vagrant up' instead")

            exec "vagrant up"
          end
        end

        rsync_cmd = ARGV.any? { |s| s.include?('rsync-auto') }

        if rsync_cmd and TeracyDev::Util.require_version_valid?(Vagrant::VERSION, "< 2.2.3")
          @logger.warn("'vagrant rsync-auto' does support rsync recovery, will use 'vagrant up' instead")

          exec "vagrant up"
        end
      end

      def configure_trigger_after(config)
        config.trigger.after :up, :reload, :resume do |trigger|
          trigger.ruby do |env, machine|
            ready = machine.guest.ready?

            unless ready
              @logger.error("guest machine is not ready")
              abort
            end

            if @cmd == 'rsync-auto'
              env.cli(@cmd)
            else
              begin
                env.cli(@cmd)

                raise NonZeroExit unless $?.exitstatus == 0
              rescue NonZeroExit
                @logger.warn('gatling-rsync-auto crashed, retrying...')

                retry
              end
            end

          end
        end
      end

    end
  end
end
