class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.references :interview_session, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
