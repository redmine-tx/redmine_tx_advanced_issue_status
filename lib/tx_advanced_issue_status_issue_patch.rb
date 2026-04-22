module TxAdvancedIssueStatusIssuePatch
  extend ActiveSupport::Concern

  included do
    # 이슈가 저장되기 전에 실행될 메서드를 update_done_ratio 로 변경합니다.
    before_save :before_update_done_ratio
    after_save :after_update_done_ratio
  end

  def after_update_done_ratio
    # 이슈 버전 변경 시 자식 이슈의 버전도 변경
    if previous_changes.include?('fixed_version_id') then
      if Setting.plugin_redmine_tx_advanced_issue_status['enable_auto_sync_target_version'] then
        if children? then
          children.each do |child|
            child.fixed_version_id = self.fixed_version_id
            child.save
          end
        end
      end
    end

    # 이슈 중요도 변경 시 자식 이슈의 중요도도 변경
    if previous_changes.include?('priority_id') then
      if Setting.plugin_redmine_tx_advanced_issue_status['enable_auto_sync_priority'] then
        if children? then
          children.each do |child|
            child.priority_id = self.priority_id
            child.save
          end
        end
      end
    end

    sync_selected_custom_fields_to_children

    # 이슈가 시작 상태가 된 경우 부모 이슈도 시작 상태로 바꿈
    if previous_changes.include?('status_id') then      
      if Setting.plugin_redmine_tx_advanced_issue_status['enable_parent_auto_update'] then
        log_debug_red "Redmine Tx Advanced Issue Status: enable_parent_auto_update"
        log_debug_red "Redmine Tx Advanced Issue Status: done_ratio_changed? #{previous_changes.include?('done_ratio')}"
        #log_debug_red "Redmine Tx Advanced Issue Status: done_ratio_was #{previous_changes['done_ratio'].first}"
        log_debug_red "Redmine Tx Advanced Issue Status: done_ratio #{done_ratio}"

        is_started_status = if children? then          
          # 자식이 있을경우 진척도가 이미 진행되었을 수 있기 떄문에 상태값을 체크
          IssueStatus.find(previous_changes['status_id'].first).default_done_ratio.to_i == 0 && 
            IssueStatus.find(status_id).default_done_ratio.to_i > 0
        else
          # 자식이 없는 말단일경우 done_ratio 만 체크
          previous_changes.include?('done_ratio') && 
            previous_changes['done_ratio'].first.to_i == 0 && 
            done_ratio.to_i > 0 && done_ratio.to_i <= 50
        end
        
        if parent_id.present? && is_started_status then
          log_debug_red "Redmine Tx Advanced Issue Status: parent_id #{self.parent_id}"
          if parent.status_id == nil || parent.status.default_done_ratio.to_i == 0 then
            log_debug_red "Redmine Tx Advanced Issue Status: parent.status_id #{parent.status_id}"
            parent.init_journal(User.current)  # 저널 생성을 위해 추가
            parent.status_id = self.status_id
            log_debug_red "Redmine Tx Advanced Issue Status: parent.status_id #{parent.status_id}"
            parent.save
          end
        end
      end
    end
  end

  def before_update_done_ratio
    prepare_syncable_custom_field_sync

    # 레드마인 코어의 상태 기반 진척도 계산이 켜져 있으면 코어 동작을 그대로 사용합니다.
    if !Issue.use_status_for_done_ratio? &&
       status_id_changed? &&
       Setting.plugin_redmine_tx_advanced_issue_status['enable_hybrid_logic'] then
      return if children?

      new_done_ratio = status.default_done_ratio
      if new_done_ratio.present?
        self.done_ratio = new_done_ratio 
        log_debug_red "Redmine Tx Advanced Issue Status: before_update_done_ratio"
      end
    end
  end

  def is_new?()
    TxAdvancedIssueStatusHelper.is_new_stage?( IssueStatus.get_stage( status_id ) )
  end

  def is_discarded?()
    TxAdvancedIssueStatusHelper.is_discarded_stage?( IssueStatus.get_stage( status_id ) )
  end

  def is_postponed?()
    TxAdvancedIssueStatusHelper.is_postponed_stage?( IssueStatus.get_stage( status_id ) )
  end

  def is_in_progress?()
    TxAdvancedIssueStatusHelper.is_in_progress_stage?( IssueStatus.get_stage( status_id ) )
  end

  def is_in_review?()
    TxAdvancedIssueStatusHelper.is_in_review_stage?( IssueStatus.get_stage( status_id ) )
  end

  def is_implemented?()
    TxAdvancedIssueStatusHelper.is_implemented_stage?( IssueStatus.get_stage( status_id ) )
  end

  def is_qa?()
    TxAdvancedIssueStatusHelper.is_qa_stage?( IssueStatus.get_stage( status_id ) )
  end

  def is_completed?()
    TxAdvancedIssueStatusHelper.is_completed_stage?( IssueStatus.get_stage( status_id ) )
  end

  def is_paused?()
    IssueStatus.is_paused?( status_id )
  end

  private

  def prepare_syncable_custom_field_sync
    @syncable_custom_field_changes_pending = false
    @previous_syncable_custom_field_values = {}

    return unless id
    return unless respond_to?(:custom_field_values_changed?) && custom_field_values_changed?
    return unless children?

    syncable_fields = syncable_issue_custom_fields
    return if syncable_fields.empty?

    @syncable_custom_field_changes_pending = true

    values_by_field_id = Hash.new { |hash, key| hash[key] = [] }
    CustomValue.where(
      customized_type: self.class.name,
      customized_id: id,
      custom_field_id: syncable_fields.map(&:id)
    ).find_each do |custom_value|
      values_by_field_id[custom_value.custom_field_id] << custom_value.value
    end

    syncable_fields.each do |field|
      raw_value = field.multiple? ? values_by_field_id[field.id] : values_by_field_id[field.id].first
      @previous_syncable_custom_field_values[field.id] = normalize_custom_field_value(field, raw_value)
    end
  end

  def sync_selected_custom_fields_to_children
    return unless @syncable_custom_field_changes_pending

    syncable_fields = @syncable_issue_custom_fields || []
    return if syncable_fields.empty?

    previous_values = @previous_syncable_custom_field_values || {}
    changed_fields = syncable_fields.select do |field|
      previous_values[field.id] != normalize_custom_field_value(field, custom_field_value(field))
    end
    return if changed_fields.empty?

    current_values = changed_fields.each_with_object({}) do |field, values|
      values[field.id] = normalized_current_custom_field_value(field)
    end

    children.each do |child|
      child_updates = {}
      child_field_ids = child.available_custom_fields.map(&:id)

      changed_fields.each do |field|
        next unless child_field_ids.include?(field.id)

        new_value = current_values[field.id]
        next if normalize_custom_field_value(field, child.custom_field_value(field)) == new_value

        child_updates[field.id.to_s] = serialize_custom_field_value(field, new_value)
      end

      next if child_updates.empty?

      child.custom_field_values = child_updates
      child.save
    end
  end

  def syncable_issue_custom_fields
    @syncable_issue_custom_fields ||= available_custom_fields.select do |field|
      field.is_a?(IssueCustomField) &&
        field.respond_to?(:sync_to_children_on_parent_change?) &&
        field.sync_to_children_on_parent_change? &&
        field.field_format != 'attachment'
    end
  end

  def normalized_current_custom_field_value(field)
    normalize_custom_field_value(field, custom_field_value(field))
  end

  def normalize_custom_field_value(field, value)
    if field.multiple?
      Array(value).map(&:to_s).reject(&:blank?).sort
    else
      normalized = value.is_a?(Array) ? value.first : value
      normalized.present? ? normalized.to_s : nil
    end
  end

  def serialize_custom_field_value(field, value)
    field.multiple? ? Array(value) : value
  end

  def log_debug_red(message)
    Rails.logger.debug "\e[31m#{message}\e[0m"
  end
end 
