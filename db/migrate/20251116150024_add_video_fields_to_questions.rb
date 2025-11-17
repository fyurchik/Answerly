class AddVideoFieldsToQuestions < ActiveRecord::Migration[7.2]
  def change
    add_column :questions, :video_id, :string
    add_column :questions, :video_url, :string
  end
end
