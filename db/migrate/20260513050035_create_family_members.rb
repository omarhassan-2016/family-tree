class CreateFamilyMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :family_members do |t|
      t.references :person, null: false, foreign_key: true
      t.references :family, null: false, foreign_key: true
      t.integer :role, null: false

      t.timestamps
    end

    add_index :family_members, [:person_id, :family_id, :role], unique: true,
              name: "index_family_members_uniqueness"
  end
end
