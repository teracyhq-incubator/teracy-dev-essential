require 'teracy-dev/config/configurator'
require 'teracy-dev/plugin'
require 'teracy-dev/util'


module TeracyDevEssential
  module Config
    class RsyncRecovery < TeracyDev::Config::Configurator

      def configure_common(settings, config)
        # The trigger is only supported by vagrant version >= 2.2.0
        require_version = ">= 2.2.0"

        unless require_version_valid?(require_version)
          @logger.warn("gatling-rsync-auto recovery is only supported by vagrant version `#{require_version}`")
          return
        end

        if gatling_rsync_installed?
          config.gatling.rsync_on_startup = false
        end

        plugins = settings['vagrant']['plugins'] ||= []

        return unless can_proceed?(plugins)

        # check rsync exist and correct config
        return unless rsync?(settings)

        @last_node = settings['nodes'].last['name']

      end

      def configure_node(settings, config)
        return if settings['name'] != @last_node

        cmd = rsync_cmd

        return if cmd.empty?

        configure_trigger_after(config, cmd)
      end

      private

      # check if plugin is installed and enabled to proceed
      def can_proceed?(plugins)
        return false if plugins.empty?

        plugin = plugins.select { |item| item['name'] == 'vagrant-gatling-rsync' }.first

        if gatling_rsync_installed?
          rsync_on_startup = plugin['options']['rsync_on_startup']

          unless TeracyDev::Util.exist? rsync_on_startup
            rsync_on_startup = true
          end

          return true if TeracyDev::Util.true?(plugin['enabled']) and TeracyDev::Util.true?(rsync_on_startup)
        end if plugin

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

      def require_version_valid?(require_version)
        vagrant_version = Vagrant::VERSION
        return TeracyDev::Util.require_version_valid?(vagrant_version, require_version)
      end

      def rsync_cmd
        cmd = ''

        if Vagrant::Util::Platform.linux?
          compatitive_version = ">= 2.2.3"

          if require_version_valid?(compatitive_version)
            cmd = 'rsync-auto'
          else
            @logger.warn("Please use vagrant `#{compatitive_version}` to fix the problem: vagrant crashed, can not be recovered.")
            @logger.warn("See more at: https://github.com/hashicorp/vagrant/issues/10460")
          end

        else
          cmd = 'gatling-rsync-auto'
        end

        cmd
      end

      def configure_trigger_after(config, cmd)
        config.trigger.after :up, :reload, :resume do |trigger|
          trigger.ruby do |env, machine|
            if cmd == 'rsync-auto'
              env.cli(cmd)
            else
              begin
                env.cli(cmd)
                raise unless $?.exitstatus == 0
              rescue
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
