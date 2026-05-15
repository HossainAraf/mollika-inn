class GalleryImage < ApplicationRecord
  belongs_to :gallery_album
  has_one_attached :image

  validates :image, presence: true

  scope :ordered, -> { order(:position) }
end
