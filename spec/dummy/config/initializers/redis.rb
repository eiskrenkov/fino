# frozen_string_literal: true

if Rails.env.development? && !ENV["DISABLE_REDIS_LOGGING"]
  module LoggingMiddleware
    PREFIX = "[Redis]"

    def call(command, redis_config)
      super.tap { debug_log_command(command) }
    end

    def call_pipelined(commands, redis_config)
      super.tap { commands.each { |command| debug_log_command(command, "PIPELINED") } }
    end

    def debug_log_command(command, additional_prefix = nil)
      Rails.logger.debug do
        command_name, *args = command

        [
          PREFIX,
          additional_prefix,
          "command=#{command_name.upcase}",
          ("args=#{args.map { |el| "\"#{el}\"" }.join(' ')}" if args.present?)
        ].compact.join(" ")
      end
    end
  end

  RedisClient.register(LoggingMiddleware)
end
