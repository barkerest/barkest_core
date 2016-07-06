require 'test_helper'

class AccessGroupTest < ActiveSupport::TestCase

  def setup
    @group = AccessGroup.new(name: 'Group X')
    @group1 = access_groups(:one)
  end

  test 'should be valid' do
    assert @group.valid?
  end

  test 'should require name' do
    assert_required @group, :name
  end

  test 'name should not be too long' do
    assert_max_length @group, :name, 100
  end

  test 'name should be unique' do
    assert_uniqueness @group, :name
  end

  test 'should allow members' do
    # must save before adding.
    @group.save!
    @group.reload

    @group.members << @group1

    assert @group.valid?

    @group.save!

    # group-x should have one member and group-1 should belong to one group.
    assert_equal 1, @group.members(true).count
    assert_equal 1, @group1.memberships(true).count

    # group-x has group-1 as a member and group-1 is a member of group-x.
    assert @group.members.include?(@group1)
    assert @group1.memberships.include?(@group)

    # group-1 equates to both group-1 and group-x for effective groups.
    assert @group1.effective_groups.include?(@group1)
    assert @group1.effective_groups.include?(@group)

    # group-x equates to group-x but not group-1 for effective groups.
    assert @group.effective_groups.include?(@group)
    assert_not @group.effective_groups.include?(@group1)

    # group-1 belongs to group-x but group-x does not belong to group-1.
    assert @group1.belongs_to?(@group)
    assert_not @group.belongs_to?(@group1)
  end

  test 'should allow ldap group assignment' do

    # group must be saved first.
    @group.save!
    @group.reload

    assert @group.valid?

    assert @group.ldap_group_list.blank?

    other_ldap_count = LdapAccessGroup.count

    list1 = [ 'GROUP A', 'GROUP B', 'GROUP C', 'GROUP D' ]
    list2 = [ 'GROUP E', 'GROUP F', 'GROUP G' ]

    [list1, list2].each do |list|

      assert @group.valid?

      # Assign to the list.
      @group.ldap_group_list = list.join("\n")
      assert @group.save

      # the list should no longer be blank.
      assert_not @group.ldap_group_list.blank?

      # and the ldap_groups count should match the list count.
      assert_equal list.length, @group.ldap_groups.count
      assert_equal other_ldap_count + list.count, LdapAccessGroup.count

      # first pass to ensure all the groups we provided exist.
      list.each do |name|
        assert_equal 1, @group.ldap_groups.where(name: name).count, "Missing '#{name}' LDAP group."
      end

      # second pass to ensure all the groups in the list were provided by us.
      @group.ldap_groups.each do |group|
        assert list.include?(group.name), "Extra '#{group.name}' LDAP group."
      end

    end

    # reset the list.
    @group.ldap_group_list = nil
    assert @group.ldap_group_list.blank?

    # assignment of arrays should also work.
    @group.ldap_group_list = []
    assert @group.ldap_group_list.blank?

    @group.ldap_group_list = list1
    assert_not @group.ldap_group_list.blank?
    assert_equal list1.length, @group.ldap_groups.count

  end

end
