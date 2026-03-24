module TxAdvancedIssueStatusIssueCustomFieldPatch
  extend ActiveSupport::Concern

  included do
    store_accessor :format_store, :sync_to_children_on_parent_change

    safe_attributes 'sync_to_children_on_parent_change'
  end

  def sync_to_children_on_parent_change?
    ActiveModel::Type::Boolean.new.cast(sync_to_children_on_parent_change)
  end
end
