class DashboardController < ApplicationController
  def show
    @total_people = Person.count
    @total_families = Family.count
    @recent_people = Person.order(updated_at: :desc).limit(8)
  end
end
