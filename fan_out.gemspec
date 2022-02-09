# frozen_string_literal: true

require_relative "lib/fan_out/version"

Gem::Specification.new do |spec|
  spec.name          = "fan_out"
  spec.version       = FanOut::VERSION
  spec.authors       = ["Yuki Nishijima"]
  spec.email         = ["yuki24@hey.com"]
  spec.summary       = "Scalable, general-purpose fan-out Rails plugin."
  spec.description   = "The fan_out gem helps build scalable fan-out inboxes."
  spec.homepage      = "https://github.com/yuki24/fan_out"
  spec.license       = "MIT"
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}#readme"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.required_ruby_version = ">= 2.6.0"

  spec.add_dependency "activejob",     ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "railties",      ">= 6.0"

  spec.add_development_dependency "activerecord", ">= 6.0"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "kredis"
  spec.add_development_dependency "elasticsearch"
end
