class Fino::Cache
  def initialize(expires_in:)
    @hash = {}
    @expirator = Expirator.new(ttl: expires_in)
  end

  def fetch(key, &)
    hash.fetch(key, &)
  ensure
    expirator.when_ready do
      @hash.clear
    end
  end
end
