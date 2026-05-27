# frozen_string_literal: true

Rails.application.configure do
  config.fino.instrument = Rails.env.development?
  config.fino.log = Rails.env.development?
  config.fino.cache_within_request = true
  config.fino.preload_before_request = false
  config.fino.instrument = true
end

Fino::InvalidValue = Class.new(Fino::Error)

class SemanticVersion
  include Comparable

  def self.correct?(value)
    Gem::Version.correct?(value)
  end

  attr_reader :version

  def initialize(version)
    @version = Gem::Version.new(version)
  end

  def <=>(other)
    version <=> other.version
  end

  def to_s
    version.to_s
  end
end

class FinoSemanticVersion
  include Fino::Setting

  self.type_identifier = :version

  class << self
    def serialize(_setting_definition, value)
      value.to_s
    end

    def deserialize(_setting_definition, raw_value)
      SemanticVersion.new(raw_value)
    end

    def validate!(raw_value)
      raise Fino::InvalidValue, "must be in vX.X.X format" unless SemanticVersion.correct?(raw_value)
    end
  end
end

Fino.register_setting_type :version, FinoSemanticVersion

Fino.configure do
  case ENV.fetch("FINO_DUMMY_ADAPTER", nil)
  when "redis"
    require "fino-redis"

    $redis = Redis.new(host: ENV.fetch("FINO_DUMMY_REDIS_HOST", "redis.fino.orb.local")) # rubocop:disable Style/GlobalVars

    adapter do
      Fino::Redis::Adapter.new($redis, namespace: "fino_dummy") # rubocop:disable Style/GlobalVars
    end
  else
    require "fino-solid"

    adapter do
      Fino::Solid::Adapter.new
    end
  end

  cache { Fino::Cache::Memory.new(expires_in: 3.seconds) }

  after_write do |setting_definition, value, overrides, variants|
    next unless setting_definition.tags.include?(:log_write)

    Fino.logger.info do
      "Setting #{setting_definition.key} was written with value #{value}".tap do |log|
        log << ", overrides #{overrides}" if overrides.any?
        log << ", variants #{variants}" if variants.any?
      end
    end
  end

  settings do
    setting :maintenance_mode,
            :boolean,
            default: false,
            description: <<~DESC.strip
              Enable maintenance mode for the system. Users will see a maintenance page when this is enabled
            DESC

    setting :api_rate_limit,
            :integer,
            default: 1000,
            description: "Maximum API requests per minute per user to prevent abuse"

    section :storefront, label: "Storefront" do
      setting :purchase_button_color,
              :select,
              options: [
                Fino::Settings::Select::Option.new(label: "Red", value: "red"),
                Fino::Settings::Select::Option.new(label: "Blue", value: "blue")
              ],
              default: "red",
              description: "Color of the purchase button"

      setting :new_checkout_flow_min_client_version,
              :version,
              default: SemanticVersion.new("1.5.0"),
              description: "Minimum client version required to use the new checkout flow"
    end

    section :llm, label: "LLM" do
      setting :model,
              :select,
              options: proc { |refresh:|
                RubyLLM.models.refresh! if refresh
                models = RubyLLM.models.chat_models

                openai_models = models.by_provider(:openai)
                anthropic_models = models.by_provider(:anthropic)

                build_pricing_label = proc do |model|
                  text_pricing = model.pricing&.text_tokens
                  next unless text_pricing && text_pricing.input && text_pricing.output

                  "$#{text_pricing.input} / $#{text_pricing.output} per 1M tokens"
                end

                [*openai_models, *anthropic_models].map do |model|
                  Fino::Settings::Select::Option.new(
                    label: model.name,
                    value: model.id,
                    metadata: {
                      provider: model.provider_class.name,
                      pricing: build_pricing_label.call(model)
                    }.compact
                  )
                end
              },
              default: "gpt-5",
              description: "Chat model for AI-powered features"

      setting :temperature,
              :float,
              default: 0.7,
              description: "Model temperature"
    end

    section :feature_toggles, label: "Feature Toggles" do
      setting :new_ui, :boolean, default: true, description: "Enable the new user interface"
      setting :beta_functionality, :boolean, default: false, description: "Enable beta functionality for testing"
    end

    section :some_external_integration, label: "External integration" do
      setting :integration_enabled,
              :boolean,
              default: false,
              description: "Acts as a circuit breaker for the integration",
              tags: [:log_write]

      setting :http_read_timeout, :integer, default: 200, unit: :ms, tags: [:log_write]
      setting :http_open_timeout, :integer, default: 100, unit: :ms, tags: [:log_write]

      setting :max_retries, :integer, default: 3, description: "Maximum number of retries for failed requests"
    end
  end
end
