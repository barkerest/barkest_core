# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
require "rails/test_help"

require 'minitest/reporters'
Minitest::Reporters.use!

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.fixtures :all
end


bad_models = 0
Dir.glob(File.expand_path('../../app/models/**/*.rb', __FILE__)).each do |file|
  # load the model definition
  require file

  model_name = File.basename(file)[0...-3].camelcase
  module_name = File.basename(File.dirname(file)).camelcase

  model_class = if self.class.const_defined?(model_name)
                  self.class.const_get(model_name)
                elsif self.class.const_defined?(module_name)
                  mod = self.class.const_get(module_name)
                  if mod.const_defined?(model_name)
                    mod.const_get(model_name)
                  else
                    nil
                  end
                else
                  nil
                end

  if model_class && model_class != BarkestCore::DbTable
    if model_class < ActiveRecord::Base
      unless model_class < BarkestCore::DbTable
        puts "\033[0;31m#{model_class.name} is not a subclass of DbTable.\033[0m"
        bad_models+=1
      end
    end
  end
end

raise StandardError.new("There are #{bad_models} models that need correcting before testing.") if bad_models > 0

