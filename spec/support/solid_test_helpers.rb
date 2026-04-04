# frozen_string_literal: true

require "active_record"
require "fino-solid"

module SolidTestHelpers
  module_function

  def setup_database(adapter_name = :sqlite3)
    config = database_config(adapter_name)

    ActiveRecord::Base.establish_connection(config)

    create_tables

    config
  end

  def database_config(adapter_name)
    case adapter_name
    when :sqlite3
      {
        adapter: "sqlite3",
        database: ":memory:"
      }
    when :postgresql
      {
        adapter: "postgresql",
        host: ENV.fetch("FINO_TEST_POSTGRES_HOST", "postgres.fino.orb.local"),
        database: ENV.fetch("FINO_TEST_POSTGRES_DB", "fino_test"),
        username: ENV.fetch("FINO_TEST_POSTGRES_USER", "postgres"),
        password: ENV.fetch("FINO_TEST_POSTGRES_PASSWORD", "")
      }
    when :trilogy
      {
        adapter: "trilogy",
        host: ENV.fetch("FINO_TEST_MYSQL_HOST", "mysql.fino.orb.local"),
        database: ENV.fetch("FINO_TEST_MYSQL_DB", "fino_test"),
        username: ENV.fetch("FINO_TEST_MYSQL_USER", "root"),
        password: ENV.fetch("FINO_TEST_MYSQL_PASSWORD", "")
      }
    when :mysql2
      {
        adapter: "mysql2",
        host: ENV.fetch("FINO_TEST_MYSQL_HOST", "mysql.fino.orb.local"),
        database: ENV.fetch("FINO_TEST_MYSQL_DB", "fino_test"),
        username: ENV.fetch("FINO_TEST_MYSQL_USER", "root"),
        password: ENV.fetch("FINO_TEST_MYSQL_PASSWORD", "")
      }
    else
      raise "Unknown database adapter: #{adapter_name}"
    end
  end

  def create_tables
    ActiveRecord::Schema.define do
      create_table :fino_settings, force: true do |t|
        t.string :key, null: false
        t.text :data
        t.timestamps
      end

      add_index :fino_settings, :key, unique: true

      create_table :fino_ab_testing_conversions, force: true do |t|
        t.string :setting_key, null: false
        t.string :variant_id, null: false
        t.string :scope, null: false
        t.datetime :converted_at, null: false
        t.timestamps
      end

      add_index :fino_ab_testing_conversions, %i[setting_key variant_id scope],
                unique: true, name: :idx_fino_conversions_unique
      add_index :fino_ab_testing_conversions, %i[setting_key variant_id],
                name: :idx_fino_conversions_lookup
    end
  end

  def clear_database
    Fino::Solid::Setting.delete_all
    Fino::Solid::Conversion.delete_all
  end

  def solid_adapter
    @solid_adapter ||= Fino::Solid::Adapter.new
  end
end
