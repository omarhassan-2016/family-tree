class RelationshipCalculatorController < ApplicationController
  def index
    @people = Person.order(:first_name, :last_name)
  end

  def result
    @person_a = Person.find(params[:person_a_id])
    @person_b = Person.find(params[:person_b_id])
    @result = Relationship::Calculator.new(@person_a, @person_b).calculate
    @people = Person.order(:first_name, :last_name)
  end
end
