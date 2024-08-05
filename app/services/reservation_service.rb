class ReservationService
  attr_reader :vehicle_type, :request_start_at, :request_end_at

  def initialize(vehicle_type:, request_start_at:, request_end_at:)
    @vehicle_type = vehicle_type
    @request_start_at = request_start_at
    @request_end_at = request_end_at
  end

  def available?
    (parking_spaces_by_vehicle_type.count - confirmed_reservations_for_requested_time.count - holds_by_request_time.count) > 0
  end

  def create_reservation
    raise 'No parking spaces available' if !available?
    raise 'Requires car_type' if vehicle_type.blank?
    raise 'Requires reservation_start_at' if request_start_at.blank?
    raise 'Requires reservation_end_at' if request_end_at.blank?

    ParkingReservation.create!(
      parking_space: optimal_parking_space,
      reservation_start_at: request_start_at,
      reservation_end_at: request_end_at,
    )
  end

  def hold_reservation
    redis_store.sadd(vehicle_type, { :start_time => request_start_at, :end_time => request_end_at, :expires_at => (Time.now + 5.minutes) }.to_json)
  end

  private

  def redis_store
    @redis_store ||= MockRedis.new
  end

  def parking_spaces_by_vehicle_type
    @parking_spaces_by_vehicle_type ||= case vehicle_type
    when 'car'
      ParkingSpace.where(can_park_car: true)
    when 'motorcycle'
      ParkingSpace.where(can_park_motorcycle: true)
    end
  end

  def confirmed_reservations_for_requested_time
    return @confirmed_reservations_for_requested_time if @confirmed_reservations_for_requested_time.present?

    reservations_by_vehicle_type = ParkingReservation.where(parking_space_id: parking_spaces_by_vehicle_type.pluck(:id))

    @confirmed_reservations_for_requested_time ||= reservations_by_vehicle_type
      .where("reservation_start_at <= ? AND reservation_end_at >= ?", request_start_at, request_start_at)
      .or(reservations_by_vehicle_type.where("reservation_start_at <= ? AND reservation_end_at >= ?", request_end_at, request_end_at))
  end

  def available_parking_spaces
    parking_spaces_by_vehicle_type - confirmed_reservations_for_requested_time.map(&:parking_space)
  end

  def holds_by_request_time
    redis_store
      .smembers(vehicle_type)
      .map { |reservation_hold| JSON.parse(reservation_hold) }
      .map { |reservation_hold| { start_time: reservation_hold['start_time'].to_datetime, end_time: reservation_hold['end_time'].to_datetime} }
      .select { |reservation_hold| (reservation_hold[:start_time] <= request_start_at && reservation_hold[:end_time] >= request_start_at) || (reservation_hold[:start_time] <= request_end_at && reservation_hold[:end_time] >= request_end_at) }
  end

  def optimal_parking_space
    case vehicle_type
    when 'car'
      available_parking_spaces.sort_by { |parking_space| parking_space.can_park_motorcycle ? 1 : 0 }.first
    when 'motorcycle'
      available_parking_spaces.sort_by { |parking_space| parking_space.can_park_car ? 1 : 0 }.first
    end
  end
end
