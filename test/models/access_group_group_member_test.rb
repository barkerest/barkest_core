require 'test_helper'

class AccessGroupGroupMemberTest < ActiveSupport::TestCase

  def setup
    @group1 = access_groups(:one)
    @group2 = access_groups(:two)
    @group3 = access_groups(:three)
    @item = AccessGroupGroupMember.new(group_id: @group1.id, member_id: @group2.id)
  end

  test 'should be valid' do
    assert @item.valid?
  end

  test 'should require group_id' do
    assert_required @item, :group_id
  end

  test 'should require member_id' do
    assert_required @item, :member_id
  end

  test 'should require unique member_id per group_id' do
    assert_uniqueness @item, :member_id, false, group_id: @group3.id
  end

end