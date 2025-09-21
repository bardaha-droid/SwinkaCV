class CreateGenerations < ActiveRecord::Migration[6.1]
  def change
    create_table :generations do |t|
      t.text :resume_text
      t.text :cover_letter
      t.string :first_name
      t.string :last_name
      t.text :address
      t.string :phone
      t.string :email

      t.timestamps
    end
  end
end
