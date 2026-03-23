class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @tags = current_organization.tags.ordered
    @tag = Tag.new
  end

  def create
    @tag = Tag.new(tag_params)
    @tag.organization = current_organization

    if @tag.save
      redirect_to tags_path, notice: "Tag created."
    else
      @tags = current_organization.tags.ordered
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @tag = current_organization.tags.find(params[:id])
    @tag.destroy
    redirect_to tags_path, notice: "Tag deleted."
  end

  private

  def tag_params
    params.require(:tag).permit(:name, :color, :description)
  end
end
