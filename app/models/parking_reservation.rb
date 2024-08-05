class ParkingReservation < ApplicationRecord
  include Uuidable

  belongs_to :parking_space
end