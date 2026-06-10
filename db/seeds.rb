# ============================================================
# Mollika Inn — Demo Seed Data
# ============================================================
puts "🌱 Seeding Mollika Inn demo data..."

[BookingRoom, Review, Booking, Rate, Room, RoomType,
 Facility, GalleryImage, GalleryAlbum, ContactInquiry, Guest, Setting].each(&:delete_all)

# ── Settings ─────────────────────────────────────────────────
Setting.create!([
  { key: "site_name",    value: "Mollika Inn" },
  { key: "site_phone",   value: "+880 1712 345678" },
  { key: "site_email",   value: "info@mollikainn.com" },
  { key: "site_address", value: "Dogachi, Boalia, Naogaon-6500, Bangladesh" },
])

# ── Room Types ────────────────────────────────────────────────
single = RoomType.create!(
  name: "Single Room", slug: "single-room",
  description: "A well-appointed single room with a cosy atmosphere, perfect for the solo traveller. Includes a comfortable single bed, en-suite bathroom, flat-screen TV, and complimentary Wi-Fi. Our Single Rooms look out over the property's manicured garden.",
  base_price_per_night: 1500, max_occupancy: 1, bed_type: "Single",
  size_sqm: 20,
  amenities: { wifi: true, air_conditioning: true, tv: true, hot_water: true, towels: true }
)
double = RoomType.create!(
  name: "Double Room", slug: "double-room",
  description: "Ideal for couples, our Double Rooms feature a king-size bed, a sitting nook with two chairs, and an en-suite bathroom with both shower and bathtub. Enjoy a quiet retreat with garden views and 24-hour room service.",
  base_price_per_night: 2500, max_occupancy: 2, bed_type: "King",
  size_sqm: 28,
  amenities: { wifi: true, air_conditioning: true, tv: true, hot_water: true, towels: true, bathtub: true, room_service: true }
)
deluxe = RoomType.create!(
  name: "Deluxe Room", slug: "deluxe-room",
  description: "Spacious and elegant, our Deluxe Rooms offer a generous seating area, premium bedding, and a private balcony. Handpicked décor inspired by local craftsmanship creates a warm, distinctive character unlike any other room.",
  base_price_per_night: 4000, max_occupancy: 3, bed_type: "King",
  size_sqm: 40,
  amenities: { wifi: true, air_conditioning: true, tv: true, hot_water: true, towels: true, bathtub: true, room_service: true, balcony: true, minibar: true }
)
family = RoomType.create!(
  name: "Family Room", slug: "family-room",
  description: "Designed for families travelling together, our Family Rooms include one king bed and two twin beds, a spacious lounge area, a children's welcome kit, and two bathrooms. Ample space for up to four guests with every comfort taken care of.",
  base_price_per_night: 5500, max_occupancy: 4, bed_type: "King + 2 Twins",
  size_sqm: 58,
  amenities: { wifi: true, air_conditioning: true, tv: true, hot_water: true, towels: true, bathtub: true, room_service: true, balcony: true, minibar: true, extra_beds: true }
)
puts "  ✓ #{RoomType.count} room types"

# ── Rooms ─────────────────────────────────────────────────────
single_rooms  = (1..4).map { |i| Room.create!(room_number: "10#{i}", floor: 1, room_type: single,  status: i <= 3 ? "available" : "occupied") }
double_rooms  = (1..4).map { |i| Room.create!(room_number: "20#{i}", floor: 2, room_type: double,  status: i <= 3 ? "available" : "occupied") }
deluxe_rooms  = (1..3).map { |i| Room.create!(room_number: "30#{i}", floor: 3, room_type: deluxe,  status: i <= 2 ? "available" : "occupied") }
family_rooms  = (1..2).map { |i| Room.create!(room_number: "F0#{i}", floor: 4, room_type: family,  status: "available") }
puts "  ✓ #{Room.count} rooms"

# ── Rates ─────────────────────────────────────────────────────
Rate.create!(name: "Standard",    room_type: single,  start_date: "2000-01-01", end_date: "2099-12-31", price_per_night: 1500, priority: 0)
Rate.create!(name: "Standard",    room_type: double,  start_date: "2000-01-01", end_date: "2099-12-31", price_per_night: 2500, priority: 0)
Rate.create!(name: "Standard",    room_type: deluxe,  start_date: "2000-01-01", end_date: "2099-12-31", price_per_night: 4000, priority: 0)
Rate.create!(name: "Standard",    room_type: family,  start_date: "2000-01-01", end_date: "2099-12-31", price_per_night: 5500, priority: 0)
Rate.create!(name: "Peak Season", room_type: deluxe,  start_date: "2025-11-01", end_date: "2026-02-28", price_per_night: 5000, priority: 1)
Rate.create!(name: "Peak Season", room_type: family,  start_date: "2025-11-01", end_date: "2026-02-28", price_per_night: 7000, priority: 1)
puts "  ✓ #{Rate.count} rates"

# ── Facilities ────────────────────────────────────────────────
Facility.create!([
  { name: "Air Conditioning",      category: "comfort",     icon_name: "snowflake", description: "Individual climate control in every room.", position: 1, visible: true },
  { name: "Free High-Speed Wi-Fi", category: "connectivity",icon_name: "wifi",      description: "Unlimited Wi-Fi throughout the property.", position: 1, visible: true },
  { name: "Restaurant & Café",     category: "amenities",   icon_name: "fork",      description: "In-house restaurant serving Bengali and continental cuisine, open 7am–11pm.", position: 2, visible: true },
  { name: "24/7 Front Desk",       category: "services",    icon_name: "bell",      description: "Round-the-clock front desk and concierge assistance.", position: 1, visible: true },
  { name: "Rooftop Garden",        category: "amenities",   icon_name: "leaf",      description: "A tranquil rooftop garden with seating — perfect for morning tea.", position: 3, visible: true },
  { name: "Laundry Service",       category: "services",    icon_name: "shirt",     description: "Same-day laundry and dry-cleaning available on request.", position: 2, visible: true },
  { name: "Daily Housekeeping",    category: "services",    icon_name: "broom",     description: "Professional housekeeping service every morning.", position: 3, visible: true },
  { name: "Safe Deposit Boxes",    category: "safety",      icon_name: "lock",      description: "Secure in-room safe and front desk safety deposit boxes.", position: 1, visible: true },
  { name: "Local Transport Help",  category: "services",    icon_name: "car",       description: "Assistance arranging rickshaws, CNGs, and day trips around Naogaon.", position: 4, visible: true },
  { name: "Room Service",          category: "services",    icon_name: "tray",      description: "In-room dining available from 7am to 10pm daily.", position: 5, visible: true },
])
puts "  ✓ #{Facility.count} facilities"

# ── Gallery ───────────────────────────────────────────────────
rooms_album    = GalleryAlbum.create!(name: "Rooms & Suites",   description: "Our beautifully furnished rooms.", position: 1, visible: true)
property_album = GalleryAlbum.create!(name: "Property & Grounds", description: "Common areas, garden, and exterior.", position: 2, visible: true)
dining_album   = GalleryAlbum.create!(name: "Restaurant & Dining", description: "Our in-house restaurant and menu.", position: 3, visible: true)

["Single Room", "Double Room", "Deluxe Room", "Family Room", "Deluxe Balcony", "Room Bathroom"].each_with_index do |cap, i|
  img = GalleryImage.new(gallery_album: rooms_album, caption: cap, position: i)
  img.save(validate: false)
end
["Hotel Exterior", "Garden Walkway", "Rooftop Garden", "Reception Lobby"].each_with_index do |cap, i|
  img = GalleryImage.new(gallery_album: property_album, caption: cap, position: i)
  img.save(validate: false)
end
["Breakfast Spread", "Chef's Special", "Dining Area"].each_with_index do |cap, i|
  img = GalleryImage.new(gallery_album: dining_album, caption: cap, position: i)
  img.save(validate: false)
end
puts "  ✓ #{GalleryAlbum.count} albums, #{GalleryImage.count} images"

# ── Guests ────────────────────────────────────────────────────
today = Date.today
g1 = Guest.create!(first_name: "Karim",   last_name: "Hossain",   email: "karim.hossain@example.com",  phone: "+880 1711 234567", nationality: "Bangladeshi")
g2 = Guest.create!(first_name: "Sadia",   last_name: "Islam",     email: "sadia.islam@example.com",    phone: "+880 1812 345678", nationality: "Bangladeshi")
g3 = Guest.create!(first_name: "James",   last_name: "Carter",    email: "james.carter@example.com",   phone: "+44 7700 900123",  nationality: "British")
g4 = Guest.create!(first_name: "Priya",   last_name: "Sharma",    email: "priya.sharma@example.com",   phone: "+91 98765 43210",  nationality: "Indian")
g5 = Guest.create!(first_name: "Ahmed",   last_name: "Rahman",    email: "ahmed.rahman@example.com",   phone: "+880 1912 456789", nationality: "Bangladeshi")
g6 = Guest.create!(first_name: "Li",      last_name: "Wei",       email: "li.wei@example.com",         phone: "+86 138 0000 0001", nationality: "Chinese")
puts "  ✓ #{Guest.count} guests"

# ── Bookings ──────────────────────────────────────────────────
b1 = Booking.create!(guest: g1, check_in_date: today,     check_out_date: today + 2, status: "checked_in",  payment_status: "paid",    num_adults: 1, total_amount: 1500 * 2, paid_amount: 1500 * 2)
b2 = Booking.create!(guest: g2, check_in_date: today,     check_out_date: today + 3, status: "checked_in",  payment_status: "paid",    num_adults: 2, total_amount: 2500 * 3, paid_amount: 2500 * 3)
b3 = Booking.create!(guest: g3, check_in_date: today + 1, check_out_date: today + 4, status: "confirmed",   payment_status: "paid",    num_adults: 2, total_amount: 4000 * 3, paid_amount: 4000 * 3)
b4 = Booking.create!(guest: g4, check_in_date: today + 2, check_out_date: today + 5, status: "confirmed",   payment_status: "partial", num_adults: 2, total_amount: 4000 * 3, paid_amount: 4000)
b5 = Booking.create!(guest: g5, check_in_date: today + 3, check_out_date: today + 6, status: "pending",     payment_status: "unpaid",  num_adults: 4, total_amount: 5500 * 3, paid_amount: 0)
b6 = Booking.create!(guest: g6, check_in_date: today + 4, check_out_date: today + 7, status: "pending",     payment_status: "unpaid",  num_adults: 2, total_amount: 2500 * 3, paid_amount: 0)
b7 = Booking.create!(guest: g1, check_in_date: today - 8, check_out_date: today - 6, status: "checked_out", payment_status: "paid",    num_adults: 1, total_amount: 1500 * 2, paid_amount: 1500 * 2)
b8 = Booking.create!(guest: g3, check_in_date: today - 14,check_out_date: today - 11,status: "checked_out", payment_status: "paid",    num_adults: 2, total_amount: 4000 * 3, paid_amount: 4000 * 3)
b9 = Booking.create!(guest: g4, check_in_date: today - 5, check_out_date: today - 3, status: "cancelled",   payment_status: "refunded",num_adults: 2, total_amount: 2500 * 2, paid_amount: 0, cancellation_reason: "Change of travel plans")

BookingRoom.create!(booking: b1, room: single_rooms[0], room_type: single, rate_per_night: 1500, total_amount: 1500 * 2)
BookingRoom.create!(booking: b2, room: double_rooms[0], room_type: double, rate_per_night: 2500, total_amount: 2500 * 3)
BookingRoom.create!(booking: b3, room: deluxe_rooms[0], room_type: deluxe, rate_per_night: 4000, total_amount: 4000 * 3)
BookingRoom.create!(booking: b4, room: deluxe_rooms[1], room_type: deluxe, rate_per_night: 4000, total_amount: 4000 * 3)
BookingRoom.create!(booking: b7, room: single_rooms[1], room_type: single, rate_per_night: 1500, total_amount: 1500 * 2)
BookingRoom.create!(booking: b8, room: deluxe_rooms[2], room_type: deluxe, rate_per_night: 4000, total_amount: 4000 * 3)
puts "  ✓ #{Booking.count} bookings"

# ── Reviews ───────────────────────────────────────────────────
Review.create!(guest: g1, booking: b7, title: "A wonderful place to stay",   body: "The room was spotlessly clean, the staff incredibly helpful and friendly. Breakfast was delicious — the paratha and egg curry alone is worth the stay. Will return every time I visit Naogaon.", rating: 5, cleanliness_rating: 5, service_rating: 5, value_rating: 5, approved: true)
Review.create!(guest: g3, booking: b8, title: "Excellent value, great staff", body: "As a traveller from the UK, I wasn't sure what to expect but Mollika Inn exceeded all my expectations. The Deluxe Room was large and well maintained. The team went out of their way to help with local transport and sightseeing advice.", rating: 5, cleanliness_rating: 5, service_rating: 5, value_rating: 5, approved: true)
Review.create!(guest: g2, booking: b2, title: "Comfortable and calm",         body: "Lovely hotel in a quiet part of town. The room was cool and comfortable, the bed very soft, and the garden view is really peaceful. The restaurant serves generous portions at fair prices.", rating: 4, cleanliness_rating: 5, service_rating: 4, value_rating: 5, approved: true)
Review.create!(guest: g4, booking: b4, title: "Very good hospitality",        body: "We chose Mollika Inn for a short break and were very pleased. Check-in was smooth, the room spacious, and the rooftop garden a real highlight. Recommended for couples and families.", rating: 4, cleanliness_rating: 4, service_rating: 5, value_rating: 4, approved: true)
puts "  ✓ #{Review.count} reviews"

# ── Contact Inquiries ─────────────────────────────────────────
ContactInquiry.create!(name: "Rahim Uddin",   email: "rahim@example.com",  phone: "+880 1911 222333", subject: "Group booking enquiry", message: "We are a group of 10 colleagues travelling to Naogaon for a workshop. Could you share your group booking rates for 5 Double Rooms for 2 nights?", status: "new")
ContactInquiry.create!(name: "Anjali Das",    email: "anjali@example.com", phone: "+91 90000 11122",  subject: "Family room availability", message: "I am planning to visit with my family of four in December. Is the Family Room available for 4 nights from 20 December?", status: "new")
puts "  ✓ #{ContactInquiry.count} inquiries"

puts ""
puts "✅ Demo seed complete! Mollika Inn is ready."
puts "   Rooms: #{Room.count} | Bookings: #{Booking.count} | Guests: #{Guest.count}"
