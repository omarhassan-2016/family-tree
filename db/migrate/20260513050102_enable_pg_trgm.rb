class EnablePgTrgm < ActiveRecord::Migration[7.2]
  def change
    enable_extension "pg_trgm"

    add_index :people, :first_name, using: :gin, opclass: :gin_trgm_ops,
              name: "index_people_on_first_name_trgm"
    add_index :people, :last_name, using: :gin, opclass: :gin_trgm_ops,
              name: "index_people_on_last_name_trgm"
  end
end
