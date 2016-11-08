class CreateSystemConfigs < ActiveRecord::Migration
  def change
    create_table :system_configs do |t|
      t.string    :key,       null: false,    limit: 128
      t.text      :value

      t.timestamps null: false
    end
    add_index :system_configs, :key, unique: true, name: :unique_system_configs
  end
end
