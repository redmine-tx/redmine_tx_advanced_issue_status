class AddStageToIssueStatus < ActiveRecord::Migration[5.2]
  def up
    add_column :issue_statuses, :stage, :integer
  end

  def down
    remove_column :issue_statuses, :stage
  end
end 
  
