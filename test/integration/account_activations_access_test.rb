require 'test_helper'

class AccountActivationsAccessTest < ActionDispatch::IntegrationTest
  access_tests_for :edit,
                   controller: 'account_activations',
                   url_helper: 'edit_account_activation_url(\'valid-token\', email: users(:two).email)',
                   allow_anon: true,
                   allow_any_user: false,
                   allow_admin: false,
                   success: 'user_path(users(:two))'

end