class InterviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_interview_session
  before_action :verify_session_ready, only: [:show]

  def show
    @current_question = find_current_question
    @question_number = @interview_session.questions.order(:id).index(@current_question) + 1 if @current_question
    @total_questions = @interview_session.questions.count
  end

  def save_answer
    question = @interview_session.questions.find(params[:question_id])

    answer = question.answer || question.build_answer

    if params[:video].present?
      answer.video.attach(params[:video])
      answer.save!

      TranscribeAnswerJob.perform_later(answer.id)

      render json: { success: true, message: 'Answer saved successfully' }
    else
      render json: { success: false, error: 'No video provided' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Question not found' }, status: :not_found
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def next_question
    current_question = @interview_session.questions.find(params[:question_id])
    next_question = @interview_session.questions.where('id > ?', current_question.id).order(:id).first
    
    if next_question
      render json: {
        success: true,
        next_question_id: next_question.id,
        question_number: @interview_session.questions.order(:id).index(next_question) + 1,
        has_next: true
      }
    else
      GenerateFeedbackJob.perform_later(@interview_session.id)

      render json: {
        success: true,
        has_next: false,
        redirect_url: interview_session_feedback_path(@interview_session)
      }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Question not found' }, status: :not_found
  end

  private

  def set_interview_session
    @interview_session = current_user.interview_sessions.find(params[:interview_session_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to interview_sessions_path, alert: 'Interview session not found'
  end

  def verify_session_ready
    unless @interview_session.ready?
      redirect_to interview_session_path(@interview_session), 
                  alert: 'Interview session is not ready yet. Please wait for videos to be generated.'
    end
  end

  def find_current_question
    if params[:question_id]
      @interview_session.questions.find(params[:question_id])
    else
      @interview_session.questions.left_joins(:answer).where(answers: { id: nil }).order(:id).first ||
      @interview_session.questions.order(:id).first
    end
  end
end

