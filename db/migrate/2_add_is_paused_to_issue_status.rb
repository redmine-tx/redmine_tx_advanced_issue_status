class AddIsPausedToIssueStatus < ActiveRecord::Migration[5.2]
  def up
    add_column :issue_statuses, :is_paused, :boolean, default: false, null: false unless column_exists?(:issue_statuses, :is_paused)
  end

  def down
    remove_column :issue_statuses, :is_paused if column_exists?(:issue_statuses, :is_paused)
  end
end
