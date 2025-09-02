# frozen_string_literal: true

Fino.configure do
  adapter :redis, host: "redis.fino.orb.local",
                  namespace: "fino_dummy"

  settings do
    setting :support_email,
            :string,
            default: "support@fino.com",
            description: "Support email address"

    setting :retries, :integer, default: 3
    setting :debug_mode, :boolean, default: false

    section :http, label: "HTTP timeouts" do
      setting :read_timeout, :float, default: 5.0
      setting :open_timeout, :float, default: 2.0
    end
  end
end
