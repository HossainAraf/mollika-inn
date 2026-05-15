class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  def self.[](key)
    find_by(key: key.to_s)&.value
  end

  def self.[]=(key, value)
    record = find_or_initialize_by(key: key.to_s)
    record.update!(value: value.to_s)
  end
end
