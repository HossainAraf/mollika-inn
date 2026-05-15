class Admin::GalleryImagesController < Admin::BaseController
  before_action :set_album

  def create
    @gallery_image = @album.gallery_images.new(gallery_image_params)
    if @gallery_image.save
      redirect_to admin_gallery_album_path(@album), notice: "Image added."
    else
      redirect_to admin_gallery_album_path(@album), alert: @gallery_image.errors.full_messages.to_sentence
    end
  end

  def update
    @gallery_image = @album.gallery_images.find(params[:id])
    if @gallery_image.update(gallery_image_params)
      redirect_to admin_gallery_album_path(@album), notice: "Image updated."
    else
      redirect_to admin_gallery_album_path(@album), alert: @gallery_image.errors.full_messages.to_sentence
    end
  end

  def destroy
    @gallery_image = @album.gallery_images.find(params[:id])
    @gallery_image.destroy
    redirect_to admin_gallery_album_path(@album), notice: "Image removed."
  end

  private

  def set_album
    @album = GalleryAlbum.find(params[:gallery_album_id])
  end

  def gallery_image_params
    params.require(:gallery_image).permit(:caption, :position, :image)
  end
end
