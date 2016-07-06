require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:standard)
    @other_user = users(:user_3)
    @admin = users(:admin)
    @disabled_user = users(:disabled)
    @recent_user = users(:recently_disabled)
  end

  test 'should redirect edit when not logged in' do
    get edit_user_path(@user)
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect update when not logged in' do
    patch user_path(@user), user: { name: @user.name, email: @user.email }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test 'should redirect edit when logged in as wrong user' do
    log_in_as @other_user
    get edit_user_path(@user)
    assert flash.empty?
    assert_redirected_to root_url
  end

  test 'should redirect update when logged in as wrong user' do
    log_in_as @other_user
    patch user_path(@user), user: { name: @user.name, email: @user.email }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test 'should redirect destroy when not logged in' do
    assert_no_difference 'User.count' do
      delete user_path(@disabled_user)
    end
    assert_redirected_to login_url
  end

  test 'should redirect destroy when logged in as non-admin' do
    log_in_as @other_user
    assert_no_difference 'User.count' do
      delete user_path(@disabled_user)
    end
    assert_redirected_to root_url
  end

  test 'should allow destroy when logged in as admin' do
    log_in_as @admin
    assert_difference 'User.count', -1 do
      delete user_path(@disabled_user)
    end
    assert_redirected_to users_url
  end

  test 'should not destroy recently disabled users' do
    log_in_as @admin
    assert_no_difference 'User.count' do
      delete user_path(@recent_user)
    end
    assert_redirected_to users_url
  end

  test 'should not destroy active users' do
    log_in_as @admin
    assert_no_difference 'User.count' do
      delete user_path(@user)
    end
    assert_redirected_to users_url
  end

  test 'should not allow the admin attribute to be edited via web' do
    log_in_as @other_user
    assert_not @other_user.system_admin?
    patch user_path(@other_user), user: { password: 'password', password_confirmation: 'password', system_admin: '1' }
    assert_not @other_user.reload.system_admin?
  end

  test 'should redirect disable when not logged in' do
    assert_no_difference 'User.enabled.count' do
      get disable_user_path(@user)
    end
    assert_redirected_to login_url
    assert_no_difference 'User.enabled.count' do
      patch disable_user_path(@user)
    end
    assert_redirected_to login_url
  end

  test 'should redirect disable when logged in as non-admin' do
    log_in_as @other_user
    assert_no_difference 'User.enabled.count' do
      get disable_user_path(@user)
    end
    assert_redirected_to root_url
    assert_no_difference 'User.enabled.count' do
      patch disable_user_path(@user)
    end
    assert_redirected_to root_url
  end

  test 'should redirect enable when not logged in' do
    assert_no_difference 'User.enabled.count' do
      patch enable_user_path(@disabled_user)
    end
    assert_redirected_to login_url
  end

  test 'should redirect enable when logged in as non-admin' do
    log_in_as @other_user
    assert_no_difference 'User.enabled.count' do
      patch enable_user_path(@disabled_user)
    end
    assert_redirected_to root_url
  end

  test 'should disable user for admins' do
    log_in_as @admin
    assert_no_difference 'User.enabled.count' do
      get disable_user_path(@other_user)
    end
    assert_template 'users/disable_confirm'
    assert_difference 'User.enabled.count', -1 do
      patch disable_user_path(@other_user), disable_user: { reason: 'As a test' }
    end
    assert_redirected_to users_url
  end

  test 'should enable user for admins' do
    log_in_as @admin
    assert_difference 'User.enabled.count', 1 do
      patch enable_user_path(@disabled_user)
    end
    assert_redirected_to users_url
  end

  test 'unsuccessful edit' do
    get edit_user_path(@user)
    assert_redirected_to login_url
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), user: { name: '', email: 'foo@invalid', password: 'foo', password_confirmation: 'baz' }
    assert_template 'users/edit'
    assert_select 'div#error_explanation'
  end

  test 'successful edit with friendly forwarding' do
    get edit_user_path(@user)
    assert_redirected_to login_url
    log_in_as(@user)
    assert_redirected_to edit_user_path(@user)
    name = 'Foo Bar'
    email = 'foo@bar.com'
    pwd = ''
    patch user_path(@user), user: { name: name, email: email, password: pwd, password_confirmation: pwd }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
    pwd = 'new-password'
    patch user_path(@user), user: { name: name, email: email, password: pwd, password_confirmation: pwd }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert @user.authenticate(pwd)
  end


end

