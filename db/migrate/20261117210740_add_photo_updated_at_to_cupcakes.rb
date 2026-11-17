class AddPhotoUpdatedAtToCupcakes < ActiveRecord::Migration[8.1]
  def change
    add_column :cupcakes, :photo_updated_at, :datetime
  end
end
