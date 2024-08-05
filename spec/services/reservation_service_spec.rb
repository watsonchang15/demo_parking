RSpec.describe ReservationService do
  let!(:car_only_space_1) { ParkingSpace.create(can_park_car: true, can_park_motorcycle: false) }
  let!(:car_only_space_2) { ParkingSpace.create(can_park_car: true, can_park_motorcycle: false) }

  let!(:motorcycle_only_space_1) { ParkingSpace.create(can_park_car: false, can_park_motorcycle: true) }
  let!(:motorcycle_only_space_2) { ParkingSpace.create(can_park_car: false, can_park_motorcycle: true) }

  let!(:hybrid_space_1) { ParkingSpace.create(can_park_car: true, can_park_motorcycle: true) }
  let!(:hybrid_space_2) { ParkingSpace.create(can_park_car: true, can_park_motorcycle: true) }

  let(:future_date) { (Date.today + 7.days).to_s }
  let(:request_start_at) { "#{future_date} 5PM".to_datetime }
  let(:request_end_at) { "#{future_date} 8PM".to_datetime }

  let(:redis_store) { MockRedis.new }

  before do
    allow(MockRedis).to receive(:new).and_return(redis_store)
  end

  describe '#available?' do
    subject { described_class.new(vehicle_type: vehicle_type, request_start_at: request_start_at, request_end_at: request_end_at).available? }

    context 'car' do
      let(:vehicle_type) { 'car' }

      context 'when there are no reservations' do
        it 'returns true' do
          expect(ParkingReservation.all).to be_empty
          expect(subject).to be(true)
        end
      end

      context 'when there are existing holds (no availability)' do
        before do
          described_class.new(vehicle_type: vehicle_type, request_start_at: request_start_at, request_end_at: request_end_at).hold_reservation
        end

        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 4PM", reservation_end_at: "#{future_date} 8PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_3) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 3PM", reservation_end_at: "#{future_date} 7PM")}  

        it 'returns false' do
          expect(subject).to be(false)
        end
      end

      context 'when the hold is not for a car' do
        before do
          described_class.new(vehicle_type: 'motorcycle', request_start_at: request_start_at, request_end_at: request_end_at).hold_reservation
        end

        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 4PM", reservation_end_at: "#{future_date} 8PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_3) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 3PM", reservation_end_at: "#{future_date} 7PM")}  

        it 'returns true' do
          expect(subject).to be(true)
        end
      end

      context 'car only spaces are fully booked but hybrid spaces are open' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 5PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
  
        it 'returns true' do
          expect(subject).to be(true)
        end
      end
  
      context 'hybrid spaces are fully booked but car only spaces are available' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 5PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: hybrid_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
  
        it 'returns true' do
          expect(subject).to be(true)
        end
      end

      context 'fully booked' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 4PM", reservation_end_at: "#{future_date} 8PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_3) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 3PM", reservation_end_at: "#{future_date} 7PM")}
        let!(:existing_reservation_4) { ParkingReservation.create!(parking_space: hybrid_space_2, reservation_start_at: "#{future_date} 7PM", reservation_end_at: "#{future_date} 9PM")}
  
        it 'returns false' do
          expect(subject).to be(false)
        end
      end  
    end

    context 'motorcycle' do
      let(:vehicle_type) { 'motorcycle' }

      context 'when there are no reservations' do
        it 'returns true' do
          expect(ParkingReservation.all).to be_empty
          expect(subject).to be(true)
        end
      end
  
      context 'car only spaces are fully booked' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
  
        it 'returns true' do
          expect(subject).to be(true)
        end
      end

      context 'motorcycle only spaces are fully booked' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: motorcycle_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: motorcycle_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
  
        it 'returns true' do
          expect(subject).to be(true)
        end
      end

      context 'hybrid only spaces are fully booked' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: hybrid_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
  
        it 'returns true' do
          expect(subject).to be(true)
        end
      end

      context 'one hybrid and one motorcycle only spaces are available' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: motorcycle_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
  
        it 'returns true' do
          expect(subject).to be(true)
        end
      end
  
      context 'hybrid and motorcycle spaces are fully booked' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: hybrid_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_3) { ParkingReservation.create!(parking_space: motorcycle_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_4) { ParkingReservation.create!(parking_space: motorcycle_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
  
        it 'returns false' do
          expect(subject).to be(false)
        end
      end

      context 'fully booked' do
        let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 4PM", reservation_end_at: "#{future_date} 8PM")}
        let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
        let!(:existing_reservation_3) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 3PM", reservation_end_at: "#{future_date} 7PM")}
        let!(:existing_reservation_4) { ParkingReservation.create!(parking_space: hybrid_space_2, reservation_start_at: "#{future_date} 7PM", reservation_end_at: "#{future_date} 9PM")}
        let!(:existing_reservation_5) { ParkingReservation.create!(parking_space: motorcycle_only_space_1, reservation_start_at: "#{future_date} 3PM", reservation_end_at: "#{future_date} 7PM")}
        let!(:existing_reservation_6) { ParkingReservation.create!(parking_space: motorcycle_only_space_2, reservation_start_at: "#{future_date} 7PM", reservation_end_at: "#{future_date} 9PM")}
  
        it 'returns false' do
          expect(subject).to be(false)
        end
      end  
    end
  end

  describe '#hold_reservation' do
    subject { reservation_service.hold_reservation }

    let(:vehicle_type) { 'car' }
    let(:reservation_service) { described_class.new(vehicle_type: vehicle_type, request_start_at: request_start_at, request_end_at: request_end_at) }

    it 'creates a new hold with an expiration date of 5 minutes' do
      expect(redis_store.smembers(vehicle_type)).to be_empty
      subject
      expect(redis_store.smembers(vehicle_type)).to_not be_empty

      space_hold = JSON.parse(redis_store.smembers(vehicle_type).first)
      expect(space_hold['expires_at']).to be <= (Time.now + 5.minutes)
    end
  end

  describe '#create_reservation' do
    subject { described_class.new(vehicle_type: vehicle_type, request_start_at: request_start_at, request_end_at: request_end_at).create_reservation }

    let(:vehicle_type) { 'car' }

    context 'no other reservations or holds' do
      it 'creates a reservation' do
        expect { subject }.to change { ParkingReservation.count }.by(1)
      end
    end

    context 'when all spaces are either reserved or on hold' do
      before do
        described_class.new(vehicle_type: vehicle_type, request_start_at: request_start_at, request_end_at: request_end_at).hold_reservation
      end

      let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 4PM", reservation_end_at: "#{future_date} 8PM")}
      let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
      let!(:existing_reservation_3) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 3PM", reservation_end_at: "#{future_date} 7PM")}  

      it 'errors' do
        expect { subject }.to raise_error('No parking spaces available')
      end
    end

    context 'when there are no spaces available' do
      let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
      let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: hybrid_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
      let!(:existing_reservation_3) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
      let!(:existing_reservation_4) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}

      it 'errors' do
        expect { subject }.to raise_error('No parking spaces available')
      end
    end

    context 'when the request is for a car and there are both hybrid and car only spaces available' do
      let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: hybrid_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
      let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}

      it 'creates a reservation and prioritizes car only' do
        expect { subject }.to change { ParkingReservation.count }.by(1)

        expect(ParkingReservation.last.parking_space).to be_in([car_only_space_1, car_only_space_2])
      end
    end

    context 'when there are only hybrid spaces available' do
      let!(:existing_reservation_1) { ParkingReservation.create!(parking_space: car_only_space_1, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}
      let!(:existing_reservation_2) { ParkingReservation.create!(parking_space: car_only_space_2, reservation_start_at: "#{future_date} 2PM", reservation_end_at: "#{future_date} 6PM")}

      it 'creates a reservation for the hybrid space' do
        subject

        expect(ParkingReservation.last.parking_space).to be_in([hybrid_space_1, hybrid_space_2])
      end
    end
  end
end
