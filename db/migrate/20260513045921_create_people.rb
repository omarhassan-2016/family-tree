class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      t.string :gedcom_id
      t.string :first_name, null: false
      t.string :last_name
      t.string :maiden_name
      t.string :suffix
      t.integer :gender, default: 0
      t.date :birth_date
      t.string :birth_place
      t.date :death_date
      t.string :death_place
      t.text :notes

      t.timestamps
    end

    add_index :people, :gedcom_id, unique: true, where: "gedcom_id IS NOT NULL"
    add_index :people, :last_name
    add_index :people, :first_name
  end
end
