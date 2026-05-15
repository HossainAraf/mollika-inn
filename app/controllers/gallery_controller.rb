class GalleryController < ApplicationController
  skip_before_action :require_authentication

  def index
    @albums = GalleryAlbum.visible.includes(gallery_images: { image_attachment: :blob }).ordered
  end
end
