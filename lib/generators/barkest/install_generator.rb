require 'rubygems'

module Barkest

  ##
  # Installs Barkest modules into an application.
  class InstallGenerator < Rails::Generators::Base

    desc 'Installs the Barkest functionality into your application.'

    def self.register(installer)
      installers << installer unless installers.include?(installer)
    end

    def install_modules
      installers.each do |inst|
        sep = '-' + ('=---' * 19) + '=-'
        tell "#{sep}\nProcessing #{inst.class}\n#{sep}", :bold
        inst.public_methods(false).each { |method| inst.send(method) }
      end
    end

    private

    def installers
      @installers ||= [ BarkestCore::InstallGenerator ]
    end

  end
end
