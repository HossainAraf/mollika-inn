module ApplicationHelper
  def status_badge_class(status)
    case status.to_s
    when "confirmed"   then "bg-green-100 text-green-800"
    when "pending"     then "bg-yellow-100 text-yellow-800"
    when "completed"   then "bg-blue-100 text-blue-800"
    when "cancelled"   then "bg-red-100 text-red-800"
    when "checked_in"  then "bg-teal-100 text-teal-800"
    when "checked_out" then "bg-gray-100 text-gray-700"
    when "new"         then "bg-yellow-100 text-yellow-800"
    when "read"        then "bg-blue-100 text-blue-800"
    when "replied"     then "bg-green-100 text-green-800"
    else "bg-gray-100 text-gray-600"
    end
  end

  # Read a site setting from the DB with optional fallback.
  # Usage: site_setting("site_name", "My Hotel")
  def site_setting(key, fallback = nil)
    Setting[key].presence || fallback
  end
end
