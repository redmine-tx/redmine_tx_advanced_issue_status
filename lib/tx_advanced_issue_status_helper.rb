module TxAdvancedIssueStatusHelper
  include Redmine::I18n

  # Stage 상수 정의
  STAGE_DISCARDED   = -2
  STAGE_POSTPONED   = -1
  STAGE_NEW         = 0
  STAGE_SCOPING     = 1
  STAGE_IN_PROGRESS = 2
  STAGE_REVIEW      = 3
  STAGE_IMPLEMENTED   = 4
  STAGE_QA            = 5
  STAGE_COMPLETED     = 6

  STAGE_OPTIONS = {
      STAGE_DISCARDED   => :label_stage_discarded,
      STAGE_POSTPONED   => :label_stage_postponed,
      STAGE_NEW         => :label_stage_new,
      STAGE_SCOPING     => :label_stage_scoping,
      STAGE_IN_PROGRESS => :label_stage_in_progress,
      STAGE_REVIEW      => :label_stage_review,
      STAGE_IMPLEMENTED => :label_stage_implemented,
      STAGE_QA          => :label_stage_qa,
      STAGE_COMPLETED   => :label_stage_completed
  }

  def self.is_new_stage?( stage )
    stage == STAGE_NEW
  end

  def self.is_discarded_stage?( stage )
    stage == STAGE_DISCARDED
  end

  def self.is_postponed_stage?( stage )
    stage == STAGE_POSTPONED
  end  

  def self.is_in_progress_stage?( stage )
    stage == STAGE_IN_PROGRESS || stage == STAGE_REVIEW
  end  

  def self.is_in_review_stage?( stage )
    stage == STAGE_REVIEW
  end  

  def self.is_implemented_stage?( stage )
    stage.to_i >= STAGE_IMPLEMENTED
  end

  def self.is_qa_stage?( stage )
    stage == STAGE_QA
  end  

  def self.is_completed_stage?( stage )
    stage == STAGE_COMPLETED
  end

  @@all_issue_statuses = nil
  @@all_issue_statuses_updated_at = nil

  def self.all_issue_statuses
    if @@all_issue_statuses.nil? || @@all_issue_statuses_updated_at < Time.now - 5.minute then
      @@all_issue_statuses = IssueStatus.all
      @@all_issue_statuses_updated_at = Time.now
    end
    @@all_issue_statuses
  end  
end