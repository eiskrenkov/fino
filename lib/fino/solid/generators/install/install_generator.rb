# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Fino
  module Solid
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        include ::ActiveRecord::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        def copy_migration
          migration_template "create_fino_settings.rb.tt", File.join(db_migrate_path, "create_fino_settings.rb")
        end

        private

        def db_migrate_path
          "db/migrate"
        end
      end
    end
  end
end
