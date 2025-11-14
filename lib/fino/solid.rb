# frozen_string_literal: true

require "active_record"

module Fino
  module Solid
    mattr_accessor :connects_to

    class << self
      def configure(&block)
        instance_eval(&block)
      end
    end
  end
end

require "fino/solid/record"
require "fino/solid/setting"
require "fino/solid/adapter"
require "fino/solid/railtie" if defined?(Rails::Railtie)

require "fino/solid/generators/install/install_generator"
