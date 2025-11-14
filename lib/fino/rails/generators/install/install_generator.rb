# frozen_string_literal: true

require "rails/generators"

module Fino
  module Rails
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        def copy_initializer
          template "fino.rb.tt", "config/initializers/fino.rb"
        end

        def install_solid_adapter
          return unless fino_solid_available?

          generate "fino:solid:install"
        end

        private

        def fino_solid_available?
          require "fino-solid"
          true
        rescue LoadError
          false
        end

        def fino_redis_available?
          require "fino-redis"
          true
        rescue LoadError
          false
        end
      end
    end
  end
end
