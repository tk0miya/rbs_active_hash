# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"

  configure_code_diagnostics(D::Ruby.lenient)
  implicitly_returns_nil!
end
