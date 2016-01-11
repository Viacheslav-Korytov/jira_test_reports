class AddCompleteDateToTestPreparations < ActiveRecord::Migration
  def change
    add_column :test_preparations, :complete_date, :datetime
  end
end
