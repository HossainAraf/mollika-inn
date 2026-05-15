# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here is idempotent and can be executed repeatedly.

require "open-uri"

puts "Seeding Mollika Inn public data..."

# -- Site settings --
Setting.find_or_create_by!(key: "site_name") do |s|
  s.value = "Mollika Inn"
end

Setting.find_or_create_by!(key: "site_address") do |s|
  s.value = "Dogachi, Boalia, Naogaon-6500, Bangladesh"
end

Setting.find_or_create_by!(key: "site_email") do |s|
  s.value = "info@mollikainn.com"
end

Setting.find_or_create_by!(key: "site_phone") do |s|
  s.value = "Call for booking"
end

# -- Facilities --
facilities = [
  { name: "Air conditioning", category: "comfort", description: "Rooms with AC" },
  { name: "Housekeeping Services", category: "services", description: "Daily housekeeping" },
  { name: "Front Desk Assistance", category: "services", description: "24/7 front desk" },
  { name: "Free Wi-Fi", category: "connectivity", description: "Free Wi-Fi across property" }
]

facilities.each_with_index do |attrs, i|
  f = Facility.find_or_initialize_by(name: attrs[:name])
  f.assign_attributes(attrs.merge(position: i + 1, visible: true)) if f.respond_to?(:visible=)
  f.save!
end

# -- Room types (from public site) --
room_types = [
  { name: "Single Room", description: "A comfortable single room with basic amenities.", max_occupancy: 1, base_price_per_night: 1500.0 },
  { name: "Double Room", description: "A cosy double room suitable for two guests.", max_occupancy: 2, base_price_per_night: 2500.0 },
  { name: "Deluxe Room", description: "Spacious deluxe room with added comfort and seating area.", max_occupancy: 3, base_price_per_night: 4000.0 },
  { name: "Family Room", description: "Large family room with sofa and extra beds for families.", max_occupancy: 4, base_price_per_night: 5500.0 }
]

room_types.each do |rt|
  r = RoomType.find_or_initialize_by(name: rt[:name])
  r.description = rt[:description]
  r.max_occupancy = rt[:max_occupancy]
  r.base_price_per_night = rt[:base_price_per_night]
  r.amenities = { "basic" => [ "TV", "Tea/Coffee", "Wardrobe", "Mirror" ] }
  r.save!
end

# -- Rates: create a default rate for each room type (idempotent) --
RoomType.find_each do |rt|
  Rate.find_or_create_by!(room_type: rt, name: "Standard", start_date: Date.new(2000, 1, 1), end_date: Date.new(2099, 12, 31)) do |rate|
    rate.price_per_night = rt.base_price_per_night || 0
    rate.priority = 0
  end
end

# -- Gallery: create an album and seed images from the public WP gallery --
gallery_urls = [
  "https://www.mollikainn.com/wp-content/uploads/photo-gallery/1_(1).jpg",
  "https://www.mollikainn.com/wp-content/uploads/photo-gallery/2_(1).jpg",
  "https://www.mollikainn.com/wp-content/uploads/photo-gallery/3_(1).jpg",
  "https://www.mollikainn.com/wp-content/uploads/photo-gallery/4_(1).jpg",
  "https://www.mollikainn.com/wp-content/uploads/photo-gallery/5_(1).jpg",
  "https://www.mollikainn.com/wp-content/uploads/photo-gallery/6_(1).jpg",
  "https://www.mollikainn.com/wp-content/uploads/photo-gallery/8_(1).jpg"
]

album = GalleryAlbum.find_or_create_by!(name: "Main Gallery") do |a|
  a.description = "Photos from Mollika Inn"
  a.visible = true if a.respond_to?(:visible=)
end

gallery_urls.each_with_index do |url, idx|
  # Skip if an image with same filename already exists for this album
  begin
    filename = File.basename(URI.parse(url).path)
  rescue => e
    puts "Warning: invalid gallery URL #{url}: #{e.message}"
    next
  end

  existing = album.gallery_images.find { |gi| gi.image.attached? && gi.image.filename.to_s == filename }
  next if existing

  begin
    file = URI.open(url)
  rescue => download_err
    puts "Warning: failed to download #{url}: #{download_err.message}"
    next
  end

  gi = album.gallery_images.build(caption: "MollikaInn photo #{idx + 1}", position: idx + 1)
  begin
    gi.image.attach(io: file, filename: filename)
    gi.save!
    puts "Attached gallery image: #{filename}"
  rescue => attach_err
    puts "Warning: failed to attach #{url}: #{attach_err.message}"
    next
  ensure
    file.close if file.respond_to?(:close)
  end
end

puts "Mollika Inn seed complete. Run bin/rails db:seed to execute."
