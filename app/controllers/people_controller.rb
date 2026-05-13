class PeopleController < ApplicationController
  before_action :set_person, only: [:show, :edit, :update, :destroy]

  def index
    @people = Person.order(:last_name, :first_name).page(params[:page])
  end

  def show
    @parents = @person.parents
    @children = @person.children
    @spouses = @person.spouses
    @siblings = @person.siblings
    @timeline = @person.timeline_events
  end

  def new
    @person = Person.new
  end

  def create
    @person = Person.new(person_params)

    # Duplicate detection before save
    @duplicates = Person.find_potential_duplicates(
      first_name: @person.first_name,
      last_name: @person.last_name,
      birth_date: @person.birth_date
    )

    # If duplicates found and user hasn't confirmed, show warning
    if @duplicates.any? && params[:confirmed] != "true"
      render :new_with_duplicates, status: :unprocessable_entity
      return
    end

    respond_to do |format|
      if @person.save
        format.html { redirect_to @person, notice: "#{@person.full_name} was successfully created." }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @person.update(person_params)
        format.html { redirect_to @person, notice: "#{@person.full_name} was successfully updated." }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    name = @person.full_name
    @person.destroy

    respond_to do |format|
      format.html { redirect_to people_path, notice: "#{name} was successfully deleted." }
      format.turbo_stream
    end
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

  def person_params
    params.require(:person).permit(
      :first_name, :last_name, :maiden_name, :suffix,
      :gender, :birth_date, :birth_place, :death_date, :death_place, :notes, :rich_notes,
      :avatar
    )
  end
end
