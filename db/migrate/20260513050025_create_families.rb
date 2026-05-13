class CreateFamilies < ActiveRecord::Migration[7.2]
  def change
    create_table :families do |t|
      t.string :gedcom_id
      t.date :marriage_date
      t.string :marriage_place

      t.timestamps
    end

    add_index :families, :gedcom_id, unique: true, where: "gedcom_id IS NOT NULL"
  end
end
