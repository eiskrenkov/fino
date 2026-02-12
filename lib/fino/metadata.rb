# frozen_string_literal: true

require_relative "version"

module Fino
  module_function

  def metadata(spec)
    spec.metadata["source_code_uri"]       = spec.homepage
    spec.metadata["bug_tracker_uri"]       = "#{spec.homepage}/issues"
    spec.metadata["rubygems_mfa_required"] = "true"
  end
end
