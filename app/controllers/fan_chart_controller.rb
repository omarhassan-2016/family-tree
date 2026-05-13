class FanChartController < ApplicationController
  def show
    @person = Person.find(params[:person_id])
    @arcs = Tree::FanChartBuilder.new(@person, generations: 4).build_arcs

    respond_to do |format|
      format.html
      format.json { render json: @arcs }
    end
  end
end
