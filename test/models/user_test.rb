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

  test 'datetime overrides are in place' do
    # we're just picking one attribute to test: 'activated_at'
    # in the User model, this attribute is given no special care and is in fact defaulted to Time.zone.now.
    # we want to ensure that values coming out of ActiveRecord are always UTC.
    [
        # valid with both TimeZoneConversion and UtcConversion
        'Time.now',
        'Time.zone.now',
        '"2016-12-19"',
        '"2016-12-19 15:45"',

        # valid with UtcConversion only.
        'Date.today',
        '"12/19/2016"',
        '"12/19/2016 3:45 pm"',

    ].each do |item|
      val = eval(item)

      # set the value then save/load to ensure we read the value from the database.
      @user.activated_at = val
      @user.save!
      @user.reload

      # basic checks.
      assert_not_nil @user.activated_at,        "Failed to set to #{item}"
      assert @user.activated_at.is_a?(Time),    "#{item} not converted to Time"
      assert @user.activated_at.utc?,           "#{item} not returned in UTC"

      # finally an equality check (based on total seconds since the unix epoch)
      assert_equal Time.utc_parse(val).tv_sec,  @user.activated_at.tv_sec
    end
  end

end
