class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @people = @query.length >= 2 ? Person.search(@query).limit(20) : Person.none

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
