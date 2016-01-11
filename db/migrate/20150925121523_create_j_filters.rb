class CreateJFilters < ActiveRecord::Migration
  def change
    create_table :j_filters do |t|
      t.string :body

      t.timestamps
    end
	add_index :j_filters, :body
	add_index :j_filters, :updated_at
  end
end
