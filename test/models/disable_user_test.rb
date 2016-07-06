require 'test_helper'

class DisableUserTest < ActiveSupport::TestCase

  def setup
    @user = users(:user_5)
    @item = DisableUser.new(user: @user, reason: 'Some valid reason')
  end

  test 'should be valid' do
    assert @item.valid?
  end

  test 'should require reason' do
    assert_required @item, :reason
  end

  test 'should require user' do
    assert_required @item, :user
  end

  test 'user must be enabled' do
    @user.enabled = false
    assert_not @item.valid?
  end

end