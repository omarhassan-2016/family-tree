class FamiliesController < ApplicationController
  before_action :require_contributor, except: [:show]
  def show
    @family = Family.find(params[:id])
  end

  def create
    @family = Family.new(family_params)
    if @family.save
      redirect_to @family, notice: "Family created."
    else
      redirect_back fallback_location: root_path, alert: "Could not create family."
    end
  end

  def destroy
    @family = Family.find(params[:id])
    @family.destroy
    redirect_to people_path, notice: "Family removed."
  end

  private

  def family_params
    params.require(:family).permit(:marriage_date, :marriage_place)
  end
end
