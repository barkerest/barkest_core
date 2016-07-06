require 'test_helper'

class LdapAccessGroupTest < ActiveSupport::TestCase
  def setup
    @item = LdapAccessGroup.new(
        group: access_groups(:two),
        name: 'Ldap Group 2'
    )
  end

  test 'should be valid' do
    assert @item.valid?
  end

  test 'should require group' do
    assert_required @item, :group
  end

  test 'should require name' do
    assert_required @item, :name
  end

  test 'name should not be too long' do
    assert_max_length @item, :name, 200
  end

  test 'name should be unique' do
    assert_uniqueness @item, :name, :group => access_groups(:three)
  end

end
