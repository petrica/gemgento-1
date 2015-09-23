# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gemgento/version'

Gem::Specification.new do |gem|
  gem.name = 'gemgento'
  gem.version = Gemgento::VERSION
  gem.authors = ['Philip Vasilevski', 'Kevin Pheasey']
  gem.email = ['phil@mauinewyork.com', 'kevin@kpheasey.com']
  gem.description = %q{rails based magento bridge for ecommerce}
  gem.summary = %q{gemgento rails magento integration ecommerce platform}
  gem.homepage = 'http://gemgento.com'

  gem.files = `git ls-files`.split($/)
  gem.executables = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'activeadmin', '>= 1.0.0.pre1'
  gem.add_dependency 'jbuilder', '>= 2.1.3'
  gem.add_dependency 'coffee-rails', '>= 4.0.0'
  gem.add_dependency 'devise', '>= 3.2.2'
  gem.add_dependency 'haml', '>= 4.0.0'
  gem.add_dependency 'kaminari', '>= 0.14'
  gem.add_dependency 'mysql2', '>= 0.3'
  gem.add_dependency 'paperclip', '>= 4.0.0'
  gem.add_dependency 'paperclip-meta', '>= 1.1.0'
  gem.add_dependency 'rails', '>= 4.1'
  gem.add_dependency 'responders', '>= 0.9'
  gem.add_dependency 'sass-rails', '>= 4.0.0'
  gem.add_dependency 'savon', '~> 2.2.0'
  gem.add_dependency 'shopify_api', '~> 3.2.4'
  gem.add_dependency 'sidekiq', '>= 2.17.4'
  gem.add_dependency 'spreadsheet', '~> 0.8.5'
  gem.add_dependency 'state_machine', '>= 1.2.0'
  gem.add_dependency 'picturefill', '>= 0.1.3'

  # testing
  gem.add_development_dependency 'rspec-rails'
  gem.add_development_dependency 'factory_girl_rails'
  gem.add_development_dependency 'faker', '~> 1.4.3'
  gem.test_files = Dir['spec/**/*']
end
