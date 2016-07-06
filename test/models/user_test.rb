require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = User.new(
        name: 'John Doe',
        email: 'john.doe@example.com',
        password: 'password',
        password_confirmation: 'password'
    )
  end

  test 'should be valid' do
    assert @user.valid?
  end

  test 'should require name' do
    assert_required @user, :name
  end

  test 'should require email' do
    assert_required @user, :email
  end

  test 'name should not be too long' do
    assert_max_length @user, :name, 100
  end

  test 'email should not be too long' do
    assert_max_length @user, :email, 255, end: '@example.com'
  end

  test 'disabled_reason should not be too long' do
    assert_max_length @user, :disabled_reason, 200
  end

  test 'last_ip should not be too long' do
    assert_max_length @user, :last_ip, 64
  end

  test 'email should be unique' do
    assert_uniqueness @user, :email
  end

  test 'email validation should accept valid addresses' do
    valid = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp alice+bob@bax.cn]

    valid.each do |address|
      @user.email = address
      assert @user.valid?, "#{address.inspect} should be valid"
    end
  end

  test 'email validation should reject invalid addresses' do
    invalid = %w[user@example,com user_at_foo.org user.name@example. foo@bar_baz.com foo@bar+baz.com @example.com user@ user user@..com user@example..com]
    invalid.each do |address|
      @user.email = address
      assert_not @user.valid?, "#{address.inspect} should be invalid"
    end
  end

  test 'email address should be lowercase' do
    @user.email = 'Not-Lower_Case@EXample.COM'
    assert @user.valid?
    @user.save!
    assert @user.valid?
    @user.reload
    assert_equal 'not-lower_case@example.com', @user.email
  end

  test 'should require password' do
    @user.password = @user.password_confirmation = ' ' * 6
    assert_not @user.valid?
  end

  test 'password should have a minimum length' do
    @user.password = @user.password_confirmation = 'a' * 6
    assert @user.valid?
    @user.password = @user.password_confirmation = 'a' * 5
    assert_not @user.valid?
  end

  test 'system admin requires user to be enabled' do
    @user.system_admin = true
    @user.enabled = true
    assert @user.system_admin?
    @user.enabled = false
    assert_not @user.system_admin?
  end

  test 'authenticated should return false for nil digest' do
    assert_not @user.authenticated?(:remember, '')
  end

end
