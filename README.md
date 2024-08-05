# README

This is a demo parking reservation app.

Fully tested with unit/integrated testing:

<img width="670" alt="Screenshot 2024-08-04 at 5 27 35 PM" src="https://github.com/user-attachments/assets/317a1f21-5d7b-400c-bffe-ea60fb4f5595">

Includes:
1. service object for:
    - checking availability [here](https://github.com/watsonchang15/demo_parking/blob/main/app/services/reservation_service.rb#L10)
    - creating new reservations [here](https://github.com/watsonchang15/demo_parking/blob/main/app/services/reservation_service.rb#L14)
    - "holding" a parking spot [here](https://github.com/watsonchang15/demo_parking/blob/main/app/services/reservation_service.rb#L27)
2. models for:
    - `parking_spaces` - represents a parking space that can accommodate one of the following: (1) cars, (2) motorcycles, (3) both
    - `parking_reservations` - represents a reservation for a given time/date for a specified parking spot
