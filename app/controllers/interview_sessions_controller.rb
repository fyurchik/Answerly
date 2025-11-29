class InterviewSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_interview_session, only: [:show, :edit, :destroy]

  def index
    @interview_sessions = current_user.interview_sessions.recent
  end

  def show
  end

  def new
    @interview_session = current_user.interview_sessions.build
  end

  def create
    @interview_session = current_user.interview_sessions.build(interview_session_params)

    if @interview_session.save
      redirect_to @interview_session, notice: 'Interview session created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def destroy
    @interview_session.destroy
    redirect_to interview_sessions_path, notice: 'Interview session deleted successfully!'
  end

  private

  def set_interview_session
    @interview_session = current_user.interview_sessions.find(params[:id])
  end

  def interview_session_params
    params.require(:interview_session).permit(:title, :job_url, :interview_category, :position_level, :questions_count, :resume)
  end
end

