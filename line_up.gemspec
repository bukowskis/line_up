require File.expand_path('../lib/line_up/version', __FILE__)

Gem::Specification.new do |spec|

  spec.authors      = %w{ bukowskis }
  spec.summary      = "Enqueue Resque Jobs directly via Redis so that you can choose the namespace yourself"
  spec.description  = "No more need to maintain two separate redis connections when using namespaces. LineUp does not even need Resque itself."
  spec.homepage     = 'https://github.com/bukowskis/line_up'
  spec.license      = 'MIT'

  spec.name         = 'line_up'
  spec.version      = LineUp::VERSION::STRING

  spec.files        = Dir['{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
  spec.require_path = 'lib'

  spec.rdoc_options.concat ['--encoding',  'UTF-8']

  spec.add_dependency('multi_json')
  spec.add_dependency('redis-namespace', '>= 1.3.0')

  spec.add_development_dependency('rspec')
end
