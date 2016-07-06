class CreateAccessGroupUserMembers < ActiveRecord::Migration
  def change
    create_table :access_group_user_members do |t|
      t.integer   :group_id,    null: false,    index: true
      t.integer   :member_id,   null: false,    index: true
    end
    add_index :access_group_user_members, [:group_id, :member_id], unique: true, name: :unique_access_group_user_members
  end
end
