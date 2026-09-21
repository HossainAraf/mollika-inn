module FacilitiesHelper
  # Centralized map of icon keys to emoji used across views
  def icon_map
    {
      "snowflake" => "❄️",
      "wifi" => "📶",
      "fork" => "🍴",
      "bell" => "🛎",
      "leaf" => "🌿",
      "shirt" => "👕",
      "broom" => "🧹",
      "lock" => "🔒",
      "car" => "🚗",
      "tray" => "🍱",
      "pool" => "🏊",
      "spa" => "💆",
      "gym" => "💪",
      "map" => "🗺",
      "coffee" => "☕",
      "mug" => "☕",
      "restaurant" => "🍽"
    }
  end

  # Options for select helpers: [ ["label", "value"], ... ]
  def icon_options_for_select
    icon_map.map { |key, emoji| [ "#{key} #{emoji}", key ] }
  end
end
module FacilitiesHelper
end
