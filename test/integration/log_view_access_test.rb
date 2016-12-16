require 'test_helper'

class LogViewAccessTest < ActionDispatch::IntegrationTest

  access_tests_for :index,
                   controller: 'log_view',
                   url_helper: 'system_log_path',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true

end