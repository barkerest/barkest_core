require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
  end

  test 'invalid signup information' do
    get signup_path
    assert_no_difference 'User.count' do
      post signup_path, user: {
          name: '',
          email: 'user@invalid',
          password: 'foo',
          password_confirmation: 'baz'
      }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
  end

  test 'valid signup information' do
    get signup_path
    assert_difference 'User.count', 1 do
      post signup_path, user: {
          name: 'Example User',
          email: 'new-user@example.com',
          password: 'password',
          password_confirmation: 'password'
      }
    end
    assert_not is_logged_in?
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    token = user.activation_token
    assert_not_nil token
    # try logging in before activation
    log_in_as user
    assert_not is_logged_in?
    # invalid activation token
    get edit_account_activation_url('invalid token', email: user.email)
    assert_not is_logged_in?
    assert_not user.reload.activated?
    # valid activation token
    get edit_account_activation_url(token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'users/show'
    assert is_logged_in?
  end

end
