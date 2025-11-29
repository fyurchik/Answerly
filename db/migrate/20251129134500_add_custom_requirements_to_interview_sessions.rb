class AddCustomRequirementsToInterviewSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :interview_sessions, :custom_requirements, :text
  end
end

