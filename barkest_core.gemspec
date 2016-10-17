$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "barkest_core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'barkest_core'
  s.version     = BarkestCore::VERSION
  s.authors     = ['Beau Barker']
  s.email       = ['beau@barkerest.com']
  s.homepage    = 'http://www.barkerest.com/'
  s.summary     = 'Core functionality for BarkerEST web apps.'
  s.description = 'Core functionality for BarkerEST web apps.'
  s.license     = 'MIT'

  s.files = `git ls-files -z`.split("\x0")
  s.files.delete 'barkest_core.gemspec'

  s.add_dependency 'rails',                           '~> 4.2.5.1'
  s.add_dependency 'sass-rails',                      '~> 5.0.4'
  s.add_dependency 'uglifier',                        '~> 3.0.0'
  s.add_dependency 'coffee-rails',                    '~> 4.1.1'
  s.add_dependency 'jquery-rails',                    '~> 4.1.1'
  s.add_dependency 'jbuilder',                        '~> 2.5.0'
  s.add_dependency 'bcrypt',                          '~> 3.1.11'
  s.add_dependency 'carrierwave',                     '~> 0.11.2'
  s.add_dependency 'will_paginate',                   '~> 3.1.0'
  s.add_dependency 'bootstrap-will_paginate',         '>= 0.0.10'
  s.add_dependency 'bootstrap-sass',                  '~> 3.3.6'
  s.add_dependency 'nokogiri',                        '~> 1.6.8'
  s.add_dependency 'tzinfo-data'
  s.add_dependency 'hex_string',                      '~> 1.0.1'
  s.add_dependency 'rubyzip',                         '~> 1.0.0'
  s.add_dependency 'axlsx',                           '~> 2.0.1'
  s.add_dependency 'axlsx_rails',                     '>= 0.4.0'
  s.add_dependency 'prawn',                           '~> 2.1.0'
  s.add_dependency 'prawn-table',                     '>= 0.2.2'
  s.add_dependency 'prawn-rails',                     '>= 0.1.1'
  s.add_dependency 'encrypted_strings',               '~> 0.3.3'
  s.add_dependency 'net-ldap',                        '>= 0.14.0'
  s.add_dependency 'thor'
  s.add_dependency 'barkest_ssh',                     '>= 1.1.12'
  s.add_dependency 'spawnling',                       '~> 2.1.6'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'web-console'


end
