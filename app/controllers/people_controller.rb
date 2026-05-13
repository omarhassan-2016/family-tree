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
  end

  def new
    @person = Person.new
  end

  def create
    @person = Person.new(person_params)

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
      :gender, :birth_date, :birth_place, :death_date, :death_place, :notes
    )
  end
end
