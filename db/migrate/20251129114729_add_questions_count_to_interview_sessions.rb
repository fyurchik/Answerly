class AddQuestionsCountToInterviewSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :interview_sessions, :questions_count, :integer, default: 5, null: false
  end
end
