class Admin::SettingsController < Admin::BaseController
  def show
    @settings = Setting.order(:key)
  end

  def update
    params.fetch(:settings, {}).each do |key, value|
      setting = Setting.find_or_initialize_by(key: key)
      setting.value = value
      setting.save
    end

    redirect_to admin_settings_path, notice: "Settings updated."
  end
end
