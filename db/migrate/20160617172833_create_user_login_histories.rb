class CreateUserLoginHistories < ActiveRecord::Migration
  def change
    create_table :user_login_histories do |t|
      t.integer     :user_id,     null: false,                index: true
      t.string      :ip_address,  null: false,    limit: 64
      t.boolean     :successful
      t.string      :message,                     limit: 200

      t.timestamps null: false
    end
  end
end
