# frozen_string_literal: true

class Fino::Rails::Preloading::Middleware
  def initialize(app, options = {})
    @app = app
    @preload = options[:preload]
  end

  def call(env)
    maybe_preload_settings(env) rescue nil # rubocop:disable Style/RescueModifier

    app.call(env)
  end

  private

  attr_reader :app, :preload

  def maybe_preload_settings(env) # rubocop:disable Metrics/MethodLength
    request = Rack::Request.new(env)

    preload_result =
      if preload.respond_to?(:call)
        preload.call(request)
      else
        preload
      end

    case preload_result
    when TrueClass
      Fino.logger.debug { "Preloading all settings" }
      Fino.settings
    when Hash
      Fino.logger.debug { "Preloading settings: #{preload_result.inspect}" }
      Fino.slice(preload_result)
    end
  end
end
