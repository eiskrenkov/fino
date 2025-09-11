# frozen_string_literal: true

require "active_support/log_subscriber"

class Fino::Rails::Instrumentation::LogSubscriber < ActiveSupport::LogSubscriber
  def pipe(event) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    return unless logger.debug?

    payload = event.payload
    operation = payload[:operation]
    pipe_name = payload[:pipe_name]
    setting_name = payload[:setting_name]
    duration = event.duration

    name = color("#{pipe_name} #{operation.to_s.upcase}", :cyan, bold: true)
    duration_text = color("(#{duration.round(1)}ms)", nil, bold: true)

    message = "  #{name} #{duration_text}"
    message += " setting=#{setting_name}" if setting_name && !setting_name.to_s.empty?

    debug(message)
  end
end

Fino::Rails::Instrumentation::LogSubscriber.attach_to :fino
