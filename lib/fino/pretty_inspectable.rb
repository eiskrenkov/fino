# frozen_string_literal: true

module Fino::PrettyInspectable
  def inspect
    attributes = inspectable_attributes.map do |key, value|
      "#{key}=#{value.inspect}"
    end

    "#<#{self.class.name} #{attributes.join(', ')}>"
  end

  def pretty_print(pp) # rubocop:disable Metrics/MethodLength
    pp.object_group(self) do
      pp.nest(1) do
        pp.breakable
        pp.seplist(inspectable_attributes, nil, :each) do |key, value|
          pp.group do
            pp.text key.to_s
            pp.text ": "
            pp.pp value
          end
        end
      end
    end
  end

  private

  def inspectable_attributes
    raise NotImplementedError
  end
end
