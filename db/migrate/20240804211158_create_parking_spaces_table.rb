class CreateParkingSpacesTable < ActiveRecord::Migration[7.1]
  def change
    create_table :parking_spaces do |t|
      t.boolean :can_park_car, default: false
      t.boolean :can_park_motorcycle, default: false
      t.string :uuid, index: { unique: true }

      t.timestamps
    end
  end
end
