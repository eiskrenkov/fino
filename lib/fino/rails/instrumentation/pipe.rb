# frozen_string_literal: true

require "active_support/notifications"

class Fino::Rails::Instrumentation::Pipe
  INSTRUMENTATION_NAMESPACE = "pipe.fino"

  include Fino::Pipe

  def initialize(pipe)
    @pipe = pipe
    setup_instrumented_methods
  end

  private

  attr_reader :pipe

  def setup_instrumented_methods # rubocop:disable Metrics/MethodLength
    Fino::Pipe.public_instance_methods(false).each do |method_name|
      self.class.define_method(method_name) do |*args, **kwargs, &block|
        payload = {
          operation: method_name,
          pipe_name: pipe.class.name,
          setting_name: extract_setting_name(method_name, args)
        }

        ActiveSupport::Notifications.instrument(INSTRUMENTATION_NAMESPACE, payload) do |instrumentation_payload|
          pipe.public_send(method_name, *args, **kwargs, &block).tap do |result|
            instrumentation_payload[:result] = result
          end
        end
      end
    end
  end

  def extract_setting_name(method_name, args) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    case method_name
    in /.*_multi$/
      args.first&.map { |sd| sd.respond_to?(:key) ? sd.key : sd.to_s }&.join(", ") || args.first&.to_s
    else
      args.first.respond_to?(:key) ? args.first.key : args.first&.to_s
    end
  end
end
