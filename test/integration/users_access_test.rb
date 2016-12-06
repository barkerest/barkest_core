require 'test_helper'

class UsersAccessTest < ActionDispatch::IntegrationTest
  access_tests_for [ :index, :show ],
                   controller: 'users',
                   allow_anon: false,
                   allow_any_user: !BarkestCore.lock_down_users,
                   allow_admin: true

  access_tests_for :new,
                   controller: 'users',
                   allow_anon: true,
                   allow_any_user: false,
                   allow_admin: false

  # the user can edit themselves, however the test should try to get the standard user to edit another user.
  # that should fail.  the other integration tests should truly test out the editing of one's self.
  access_tests_for :edit,
                   controller: 'users',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true

  access_tests_for :disable,
                   controller: 'users',
                   url_helper: 'disable_user_path(users(:one))',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true




end