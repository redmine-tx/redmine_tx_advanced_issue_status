module TxAdvancedIssueStatusIssueStatusPatch
  include Redmine::I18n
  extend ActiveSupport::Concern

  included do
    # 'stage' 속성을 안전한 속성 목록에 추가합니다.
    safe_attributes(
      'name',
      'description',
      'is_closed',
      'position',
      'default_done_ratio',
      'stage')
  end

  def stage_name
    l(TxHybridDoneratioHelper.STAGE_OPTIONS[self.stage])
  end

  def is_new?
    TxAdvancedIssueStatusHelper.is_new_stage?( self.stage )
  end

  def is_postponed?
    TxAdvancedIssueStatusHelper.is_postponed_stage?( self.stage )
  end

  def is_discarded?
    TxAdvancedIssueStatusHelper.is_discarded_stage?( self.stage )
  end

  def is_in_progress?
    TxAdvancedIssueStatusHelper.is_in_progress_stage?( self.stage )
  end

  def is_in_review?
    TxAdvancedIssueStatusHelper.is_in_review_stage?( self.stage )
  end

  def is_implemented?
    TxAdvancedIssueStatusHelper.is_implemented_stage?( self.stage )
  end

  def is_qa?
    TxAdvancedIssueStatusHelper.is_qa_stage?( self.stage )
  end

  def is_completed?
    TxAdvancedIssueStatusHelper.is_completed_stage?( self.stage )
  end

  module ClassMethods
    # 캐시 관련 클래스 변수 초기화
    @@issue_statuses = nil
    @@issue_statuses_cache_time = nil

    def is_new?( status_id )
      TxAdvancedIssueStatusHelper.is_new_stage?( get_stage( status_id ) )
    end

    def is_postponed?( status_id )
      TxAdvancedIssueStatusHelper.is_postponed_stage?( get_stage( status_id ) )
    end

    def is_discarded?( status_id )
      TxAdvancedIssueStatusHelper.is_discarded_stage?( get_stage( status_id ) )
    end

    def is_in_progress?( status_id )
      TxAdvancedIssueStatusHelper.is_in_progress_stage?( get_stage( status_id ) )
    end

    def is_in_review?( status_id )
      TxAdvancedIssueStatusHelper.is_in_review_stage?( get_stage( status_id ) )
    end

    def is_implemented?( status_id )
      TxAdvancedIssueStatusHelper.is_implemented_stage?( get_stage( status_id ) )
    end

    def is_qa?( status_id )
      TxAdvancedIssueStatusHelper.is_qa_stage?( get_stage( status_id ) )
    end 

    def is_completed?( status_id )
      TxAdvancedIssueStatusHelper.is_completed_stage?( get_stage( status_id ) )
    end

    def new_ids
      TxAdvancedIssueStatusHelper.all_issue_statuses.select{ |status| status.is_new? }.map(&:id)
    end

    def discarded_ids
      TxAdvancedIssueStatusHelper.all_issue_statuses.select{ |status| status.is_discarded? }.map(&:id)
    end

    def postponed_ids
      TxAdvancedIssueStatusHelper.all_issue_statuses.select{ |status| status.is_postponed? }.map(&:id)
    end

    def in_progress_ids
      TxAdvancedIssueStatusHelper.all_issue_statuses.select{ |status| status.is_in_progress? }.map(&:id)
    end

    def implemented_ids
      TxAdvancedIssueStatusHelper.all_issue_statuses.select{ |status| status.is_implemented? }.map(&:id)
    end

    def in_review_ids
      TxAdvancedIssueStatusHelper.all_issue_statuses.select{ |status| status.is_in_review? }.map(&:id)
    end

    def completed_ids
      TxAdvancedIssueStatusHelper.all_issue_statuses.select{ |status| status.is_completed? }.map(&:id)
    end
    

    
    def get_name( status_id )
      is = TxAdvancedIssueStatusHelper.all_issue_statuses.find { |issue_status| issue_status.id == status_id }
      is ? is.name : nil
    end

    def get_stage( status_id )
      is = TxAdvancedIssueStatusHelper.all_issue_statuses.find { |issue_status| issue_status.id == status_id }
      is ? is.stage : nil
    end  
  end
end