# frozen_string_literal: true

guard "livereload" do
  # Ignore patterns
  ignore(/^node_modules/)
  ignore(/\.git/)
  ignore(/\.log$/)
  ignore(/tmp/)

  # Watch engine views
  watch(%r{lib/fino/rails/app/views/.+\.(erb|slim)$})

  # Watch any CSS/JS assets if they exist
  watch(%r{lib/fino/rails/app/assets/.+\.(css|js)$})

  # Watch dummy app views too
  watch(%r{spec/dummy/app/views/.+\.(erb|slim)$})
end
