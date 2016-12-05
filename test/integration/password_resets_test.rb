require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:standard)
  end

  access_tests_for :new,
                   allow_anon: true,
                   allow_admin: false

  # nobody should be able to access this path, in the actual integration test it should work.
  access_tests_for :edit,
                   url_helper: 'edit_password_reset_path(\'invalid-token\')',
                   anon_failure: 'root_url',
                   allow_anon: false,
                   allow_admin: false

  test 'password resets' do
    get new_password_reset_path
    assert_template 'password_resets/new'

    # invalid email
    post password_resets_path, password_reset: { email: 'nobody@example.com' }
    assert_not flash.empty?
    assert_redirected_to root_url
    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    assert_match 'email address is not associated with an existing account', email.body.encoded

    # valid email
    post password_resets_path, password_reset: { email: @user.email }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    user = assigns(:user)
    assert_equal 2, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    assert_match edit_password_reset_path(id: user.reset_token, email: user.email), email.body.encoded
    assert_not flash.empty?
    assert_redirected_to root_url

    # wrong email
    get edit_password_reset_path(user.reset_token, email: 'nobody@example.com')
    assert_redirected_to root_url

    # inactive user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)

    # disabled user
    user.toggle!(:enabled)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:enabled)

    # wrong token
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url

    # right email and token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select 'input[name=email][type=hidden][value=?]', user.email

    # invalid password and confirmation
    patch password_reset_path(user.reset_token), email: user.email, user: { password: 'foobar', password_confirmation: 'bar-bq' }
    assert_select 'div#error_explanation'

    # empty password
    patch password_reset_path(user.reset_token), email: user.email, user: { password: '', password_confirmation: '' }
    assert_select 'div#error_explanation'

    # valid password & confirmation
    patch password_reset_path(user.reset_token), email: user.email, user: { password: 'foobaz', password_confirmation: 'foobaz' }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end

  test 'expired token' do
    get new_password_reset_path
    post password_resets_path, password_reset: { email: @user.email }
    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token),
          email: @user.email,
          user: {
              password: 'foobar',
              password_confirmation: 'foobar'
          }
    assert_response :redirect
    follow_redirect!
    assert_not flash.empty?
    regex = /password\sreset\srequest\shas\sexpired/i
    assert_match regex, response.body
  end

end
