

module BarkestCore

  ##
  # Installs BarkestCore into an application.
  class InstallGenerator < Rails::Generators::Base

    desc 'Installs the BarkestCore functionality into your application.'

    # actions are stored in the 'actions' directory.

  end
end

# load the actions
Dir.glob(File.expand_path('../actions/*.rb', __FILE__)).each { |action| require action }
