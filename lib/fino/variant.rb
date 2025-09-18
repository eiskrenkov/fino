
Fino::Variant = Struct.new(:percentage, :value) do
  def id = @id ||= SecureRandom.uuid
end
Fino::Variant::CONTROL = Object.new
