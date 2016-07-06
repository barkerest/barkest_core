class CreateLdapAccessGroups < ActiveRecord::Migration
  def change
    create_table :ldap_access_groups do |t|
      t.integer   :group_id,    null: false
      t.string    :name,        null: false,    limit: 200

      t.timestamps null: false
    end
    add_index :ldap_access_groups, [:group_id, :name], unique: true, name: :unique_ldap_access_groups
  end
end
