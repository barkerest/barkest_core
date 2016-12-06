require 'test_helper'

class SystemConfigAccessTest < ActionDispatch::IntegrationTest

  COMMON_ACCESS = {
      controller: 'system_config',
      allow_anon: false,
      allow_any_user: false,
      allow_admin: true
  }

  access_tests_for :index, COMMON_ACCESS.merge(url_helper: 'system_config_path')

  access_tests_for :restart, COMMON_ACCESS.merge(url_helper: 'system_config_restart_path', success: 'system_config_url', method: :post)

  access_tests_for :show_auth, COMMON_ACCESS.merge(url_helper: 'system_config_auth_path')

  access_tests_for :show_database, COMMON_ACCESS.merge(url_helper: 'system_config_database_path(\'test-123\')')

  access_tests_for :show_email, COMMON_ACCESS.merge(url_helper: 'system_config_email_path')

  access_tests_for :show_self_update, COMMON_ACCESS.merge(url_helper: 'system_config_self_update_path')

end