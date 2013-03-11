Gem::Specification.new do |spec|

  spec.name        = 'line_up'
  spec.version     = '0.0.1'
  spec.date        = '2013-03-11'
  spec.summary     = "Enqueue Resque Jobs directly via Redis so that you can choose the namespace yourself"
  spec.description = "See https://github.com/bukowskis/line_up"
  spec.authors     = %w{ bukowskis }
  spec.homepage    = 'https://github.com/bukowskis/line_up'

  spec.files       = Dir['Rakefile', '{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")

  spec.add_dependency('multi_json')
  spec.add_dependency('redis-namespace')

  spec.add_development_dependency('rspec')
  spec.add_development_dependency('guard-rspec')
  spec.add_development_dependency('rb-fsevent')

end
