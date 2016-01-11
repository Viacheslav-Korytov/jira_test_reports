class CreateTestPreparations < ActiveRecord::Migration
  def change
    create_table :test_preparations do |t|
      t.string :issue
      t.integer :tc_plan
      t.datetime :tc_date

      t.timestamps
    end
  end
end
