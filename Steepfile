# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"                       # Directory name
  check "Gemfile"                   # File name

  configure_code_diagnostics(D::Ruby.lenient)      # `lenient` diagnostics setting
end
