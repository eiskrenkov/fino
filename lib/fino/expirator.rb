# frozen_string_literal: true

class Expirator
  def initialize(ttl:)
    @ttl = ttl
    reset_timestamp
  end

  def when_ready
    return if current_timestamp - stored_timestamp < ttl

    yield

    reset_timestamp
  end

  private

  attr_reader :stored_timestamp, :ttl

  def reset_timestamp
    @stored_timestamp = current_timestamp
  end

  def current_timestamp
    Time.now.to_i
  end
end
