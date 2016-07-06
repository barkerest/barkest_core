class CreateAccessGroups < ActiveRecord::Migration
  def change
    create_table :access_groups do |t|
      t.string      :name,    null: false,  limit: 100

      t.timestamps            null: false
    end
    add_index :access_groups, :name, unique: true, name: :unique_access_groups
  end
end
