# frozen_string_literal: true

require "zeitwerk"
require "roda"
require "json"

Bridgetown::Current.preloaded_configuration ||= Bridgetown.configuration

require_relative "loader_hooks"
require_relative "logger"
require_relative "routes"

module Bridgetown
  module Rack
    class << self
      # @return [Bridgetown::Utils::LoadersManager]
      attr_accessor :loaders_manager
    end

    # Start up the Roda Rack application and the Zeitwerk autoloaders. Ensure the
    # Roda app is provided the preloaded Bridgetown site configuration. Handle
    # any uncaught Roda errors.
    def self.boot(*)
      self.loaders_manager =
        Bridgetown::Utils::LoadersManager.new(Bridgetown::Current.preloaded_configuration)
      Bridgetown::Current.preloaded_configuration.run_initializers! context: :server
      LoaderHooks.autoload_server_folder(
        File.join(Bridgetown::Current.preloaded_configuration.root_dir, "server")
      )
    rescue Roda::RodaError => e
      if e.message.include?("sessions plugin :secret option")
        raise Bridgetown::Errors::InvalidConfigurationError,
              "The Roda sessions plugin can't find a valid secret. Run `bin/bridgetown secret' " \
              "and put the key in a ENV var you can use to configure the session in the Roda app"
      end

      raise e
    end
  end
end
