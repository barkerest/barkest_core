require 'test_helper'

class AccessTest < ActionDispatch::IntegrationTest

  # paths that are designed for access testing.
  access_tests_for :allow_anon,
                   url_helper: 'barkest_core_test_access_allow_anon_path',
                   allow_anon: true,
                   allow_any_user: true

  access_tests_for :require_user,
                   url_helper: 'barkest_core_test_access_require_user_path',
                   allow_any_user: true

  access_tests_for :require_group_x,
                   url_helper: 'barkest_core_test_access_require_group_x_path',
                   allow_groups: ['group 1', 'group 2', 'group 3']

  access_tests_for :require_admin,
                   url_helper: 'barkest_core_test_access_require_admin_path',
                   deny_groups: ['group 1', 'group 2', 'group 3' ]


  # group management paths.
  access_tests_for [:index, :new, :create, :show, :edit, :update, :destroy],
                   controller: 'access_groups',
                   create_params: { access_group: { name: 'Test Group X'} },
                   update_params: { access_group: { name: 'Test Group X'} }





end
