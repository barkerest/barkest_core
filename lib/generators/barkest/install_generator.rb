require 'rubygems'

module Barkest

  ##
  # Installs Barkest modules into an application.
  class InstallGenerator < Rails::Generators::Base

    desc 'Installs the Barkest functionality into your application.'

    def install_modules
      BarkestCore.installers.each do |inst_name|
        require 'generators/' + inst_name.underscore
        inst = Object.const_get(inst_name).new
        sep = '-' + ('=---' * 19) + '=-'
        tell "#{sep}\nProcessing #{inst.class}\n#{sep}", :bold
        inst.public_methods(false).each { |method| inst.send(method) }
      end
    end

  end
end
