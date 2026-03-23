class CreateFinoAbTestingConversions < ActiveRecord::Migration[8.1]
  def change
    create_table :fino_ab_testing_conversions do |t|
      t.string :setting_key, null: false
      t.string :variant_id, null: false
      t.string :scope, null: false
      t.datetime :converted_at, null: false

      t.timestamps
    end

    add_index :fino_ab_testing_conversions, %i[setting_key variant_id scope],
              unique: true, name: :idx_fino_conversions_unique
    add_index :fino_ab_testing_conversions, %i[setting_key variant_id],
              name: :idx_fino_conversions_lookup
  end
end
