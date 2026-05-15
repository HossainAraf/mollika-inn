class GalleryAlbum < ApplicationRecord
  has_many :gallery_images, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true

  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(:position, :name) }

  def cover_image
    gallery_images.first
  end
end
