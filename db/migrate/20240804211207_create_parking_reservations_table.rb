class CreateParkingReservationsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :parking_reservations do |t|
      t.integer :parking_space_id
      t.datetime :reservation_start_at
      t.datetime :reservation_end_at
      t.float :duration
      t.string :code, index: { unique: true }
      t.string :uuid, index: { unique: true }

      t.timestamps
    end
  end
end
