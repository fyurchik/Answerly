class CreateOverallFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :overall_feedbacks do |t|
      t.references :interview_session, null: false, foreign_key: true
      t.integer :overall_score
      t.text :summary
      t.text :key_strengths
      t.text :areas_for_improvement
      t.text :recommendations

      t.timestamps
    end
  end
end
