class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string      :name,                  null: false,    limit: 100
      t.string      :email,                 null: false,    limit: 255
      t.boolean     :ldap,                                                default: false
      t.boolean     :activated,                                           default: false
      t.boolean     :enabled,                                             default: true
      t.boolean     :system_admin,                                        default: false
      t.string      :activation_digest
      t.string      :password_digest
      t.string      :remember_digest
      t.string      :reset_digest
      t.datetime    :activated_at
      t.datetime    :reset_sent_at
      t.integer     :disabled_by_id
      t.datetime    :disabled_at
      t.string      :disabled_reason,                       limit: 200
      t.datetime    :last_login
      t.string      :last_ip,                               limit: 64

      t.timestamps null: false
    end
    add_index :users, :email, unique: true, name: :unique_users
  end
end
