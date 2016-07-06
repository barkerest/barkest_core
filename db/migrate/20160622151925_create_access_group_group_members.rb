class CreateAccessGroupGroupMembers < ActiveRecord::Migration
  def change
    create_table :access_group_group_members do |t|
      t.integer    :group_id,   null: false,    index: true
      t.integer    :member_id,  null: false,    index: true
    end
    add_index :access_group_group_members, [ :group_id, :member_id ], unique: true, name: :unique_access_group_group_members
  end
end
