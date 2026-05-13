class TreeController < ApplicationController
  def show
    @person = Person.find(params[:person_id])
    @tree_data = Tree::Builder.new(@person, depth: 3).build

    respond_to do |format|
      format.html
      format.json { render json: @tree_data }
    end
  end
end
