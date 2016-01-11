class CreateOptions < ActiveRecord::Migration
  def change
    create_table :options do |t|
      t.string :key
      t.string :option

      t.timestamps
    end
  end
end
