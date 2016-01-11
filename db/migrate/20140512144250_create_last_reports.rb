class CreateLastReports < ActiveRecord::Migration
  def change
    create_table :last_reports do |t|
      t.string :issue
      t.integer :total
      t.integer :passed
      t.integer :failed
      t.integer :inprogress
      t.integer :p_executed
      t.integer :p_passed

      t.timestamps
    end
  end
end
