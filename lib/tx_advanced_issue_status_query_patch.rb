module TxAdvancedIssueStatusQueryPatch
  extend ActiveSupport::Concern

  included do
    # 커스텀 연산자 등록
    self.operators = self.operators.merge(
      "wk" => :label_stage_in_progress_filter,
      "im" => :label_stage_implemented_or_above
    )

    # list_status 필터에 연산자 삽입
    # 기존: ["o", "=", "!", "ev", "!ev", "cf", "c", "*"]
    # 변경: ["o", "wk"(구현중), "=", "!", "ev", "!ev", "cf", "im"(구현끝+), "c", "*"]
    list_status_ops = self.operators_by_filter_type[:list_status].dup
    o_index = list_status_ops.index("o") || 0
    list_status_ops.insert(o_index + 1, "wk")
    c_index = list_status_ops.index("c") || (list_status_ops.length - 1)
    list_status_ops.insert(c_index, "im")
    self.operators_by_filter_type = self.operators_by_filter_type.merge(
      list_status: list_status_ops
    )

    alias_method :sql_for_field_without_stage, :sql_for_field
    alias_method :sql_for_field, :sql_for_field_with_stage
  end

  def sql_for_field_with_stage(field, operator, value, db_table, db_field, is_custom_filter = false, assoc = nil)
    if field == "status_id"
      case operator
      when "wk"
        return "#{queried_table_name}.status_id IN " \
          "(SELECT id FROM #{IssueStatus.table_name} WHERE stage IN (2,3))"
      when "im"
        return "#{queried_table_name}.status_id IN " \
          "(SELECT id FROM #{IssueStatus.table_name} WHERE stage >= 4)"
      end
    end
    sql_for_field_without_stage(field, operator, value, db_table, db_field, is_custom_filter, assoc)
  end
end
