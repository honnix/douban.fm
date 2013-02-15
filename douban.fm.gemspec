lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'douban.fm/version'

Gem::Specification.new do |gem|
  gem.name          = 'douban.fm'
  gem.version       = DoubanFM::VERSION
  gem.authors       = ['honnix']
  gem.email         = ['hxliang1982@gmail.com']
  gem.description   = %q{douban.fm}
  gem.summary       = %q{douban.fm}
  gem.homepage      = 'https://github.com/honnix/douban.fm'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'ruby-mpd', '0.1.5'
  gem.add_dependency 'highline', '1.6.15'
end
