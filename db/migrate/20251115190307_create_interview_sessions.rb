class CreateInterviewSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :interview_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :job_url
      t.string :interview_category
      t.string :position_level

      t.timestamps
    end
  end
end
