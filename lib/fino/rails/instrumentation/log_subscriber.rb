# frozen_string_literal: true

require "active_support/log_subscriber"

class Fino::Rails::Instrumentation::LogSubscriber < ActiveSupport::LogSubscriber
  attach_to :fino

  def adapter(event)
    log_instrumentation_event(event)
  end

  def cache(event)
    log_instrumentation_event(event)
  end

  def log_instrumentation_event(event) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    return unless logger.debug?

    payload = event.payload
    method_name = payload[:method_name]
    class_name = payload[:class_name]
    key = payload[:key]
    duration = event.duration

    name = color("#{class_name} #{method_name.to_s.upcase}", :yellow, bold: true)
    duration_text = color("(#{duration.round(1)}ms)", nil)

    message = "  #{name} #{duration_text}"
    message += color(" key=#{key}", :blue, bold: true) if key && !key.to_s.empty?

    debug(message)
  end
end
