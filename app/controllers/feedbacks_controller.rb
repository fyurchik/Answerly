class FeedbacksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_interview_session

  def show
    @overall_feedback = @interview_session.overall_feedback
  end

  private

  def set_interview_session
    @interview_session = current_user.interview_sessions.find(params[:interview_session_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to interview_sessions_path, alert: 'Interview session not found'
  end
end

