require 'test_helper'

class SystemUpdateAccessTest < ActionDispatch::IntegrationTest

  access_tests_for :index,
                   url_helper: 'system_update_path',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true

  access_tests_for :new,
                   url_helper: 'system_update_new_path',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true,
                   success: 'status_current_url'


end