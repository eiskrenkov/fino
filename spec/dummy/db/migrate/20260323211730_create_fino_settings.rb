class CreateFinoSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :fino_settings do |t|
      t.string :key, null: false
      t.text :data

      t.timestamps
    end

    add_index :fino_settings, :key, unique: true
  end
end
