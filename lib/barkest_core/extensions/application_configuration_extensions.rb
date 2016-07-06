# :enddoc:

# alter the configuration class slightly.
Rails::Application::Configuration.class_eval do

  # redefine the 'database_configuration' method to provide defaults for test & development.
  alias :barkest_core_original_database_configuration :database_configuration

  def database_configuration
    begin
      barkest_core_original_database_configuration
    rescue => e
      # unless we are simply missing the 'database.yml' file, re-raise the error.
      # Also raise the error if we are not in test or development.  The file
      # really should be supplied for production.
      raise e unless e.inspect.include?('No such file -') && (Rails.env.test? || Rails.env.development?)

      default =
      {
          'adapter' => 'sqlite3',
          'pool' => 5,
          'timeout' => 5000
      }

      # only provide defaults for development and test.
      {
          'test' => default.merge(database: 'db/test.sqlite3'),
          'development' => default.merge(database: 'db/development.sqlite3')
      }
    end
  end



end