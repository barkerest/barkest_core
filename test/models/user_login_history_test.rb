require 'test_helper'

class UserLoginHistoryTest < ActiveSupport::TestCase

  def setup
    @user = users(:user_5)
    @item = UserLoginHistory.new(user: @user, ip_address: '1.2.3.4')
  end

  test 'should be valid' do
    assert @item.valid?
  end

  test 'should require user' do
    assert_required @item, :user
    assert_required @item, :user_id
  end

  test 'should require ip_address' do
    assert_required @item, :ip_address
  end

  test 'ip_address should not be too long' do
    assert_max_length @item, :ip_address, 64
  end

  test 'message should not be too long' do
    assert_max_length @item, :message, 200
  end

  test 'timestamps should be in utc' do
    @item.save!
    assert @item.created_at.utc?
    assert @item.updated_at.utc?
  end

end