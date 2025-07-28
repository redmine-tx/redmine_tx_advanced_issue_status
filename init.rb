Redmine::Plugin.register :redmine_tx_advanced_issue_status do
  name 'Redmine Tx Advanced Issue Status plugin'
  author 'KiHyun Kang'
  description '이슈의 상태 변경 시 부모 이슈의 완료 비율을 동기화는 유지하면서 자식 이슈의 완료 비율을 이슈 상태에 따른 진척도로 변경해 줍니다. 레드마인 전역 설정에서 이슈 상태에 따른 진척도를 꺼야 정상 작동 합니다.'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  # 플러그인 설정 정의
   settings default: {
      'enable_hybrid_logic' => true,
      'enable_auto_sync_target_version' => false,
      'enable_auto_sync_priority' => false,
      'enable_auto_sync_tag' => false,
      'enable_parent_auto_update' => false
    }, partial: 'settings/tx_advanced_issue_status'
end

Rails.application.config.after_initialize do
  require_dependency File.expand_path('lib/tx_advanced_issue_status_helper', File.dirname(__FILE__))
  require_dependency File.expand_path('lib/tx_advanced_issue_status_hook', File.dirname(__FILE__))
  require_dependency File.expand_path('lib/tx_advanced_issue_status_issue_patch', File.dirname(__FILE__))
  require_dependency File.expand_path('lib/tx_advanced_issue_status_issue_status_patch', File.dirname(__FILE__))

  ApplicationController.helper TxAdvancedIssueStatusHelper
  Issue.send(:include, TxAdvancedIssueStatusIssuePatch)
  IssueStatus.send(:include, TxAdvancedIssueStatusIssueStatusPatch)
end