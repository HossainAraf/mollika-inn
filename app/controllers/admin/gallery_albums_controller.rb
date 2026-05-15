class Admin::GalleryAlbumsController < Admin::BaseController
  before_action :set_album, only: [ :show, :edit, :update, :destroy ]

  def index
    @gallery_albums = GalleryAlbum.ordered
  end

  def show
  end

  def new
    @gallery_album = GalleryAlbum.new
  end

  def create
    @gallery_album = GalleryAlbum.new(gallery_album_params)
    if @gallery_album.save
      redirect_to admin_gallery_album_path(@gallery_album), notice: "Album created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @gallery_album.update(gallery_album_params)
      redirect_to admin_gallery_album_path(@gallery_album), notice: "Album updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @gallery_album.destroy
    redirect_to admin_gallery_albums_path, notice: "Album deleted."
  end

  private

  def set_album
    @gallery_album = GalleryAlbum.find(params[:id])
  end

  def gallery_album_params
    params.require(:gallery_album).permit(:name, :description, :position, :visible)
  end
end
