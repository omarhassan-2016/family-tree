class RelationshipsController < ApplicationController
  before_action :set_person

  def new
    @role = params[:role] # "parent", "spouse", "child"
    @available_people = Person.where.not(id: @person.id).order(:first_name, :last_name)
  end

  def create
    role = params[:role]
    related_person_id = params[:related_person_id]
    related_person = related_person_id.present? ? Person.find(related_person_id) : nil

    # Optionally create a new person inline
    if related_person.nil? && params[:person].present?
      related_person = Person.new(person_params)
      unless related_person.save
        @role = role
        @available_people = Person.where.not(id: @person.id).order(:first_name, :last_name)
        @new_person = related_person
        render :new, status: :unprocessable_entity
        return
      end
    end

    return head(:unprocessable_entity) unless related_person

    begin
      case role
      when "parent"
        add_parent(related_person)
      when "spouse"
        add_spouse(related_person)
      when "child"
        add_child(related_person)
      end

      respond_to do |format|
        format.html { redirect_to person_path(@person), notice: "#{related_person.full_name} added as #{role}." }
        format.turbo_stream { redirect_to person_path(@person), notice: "#{related_person.full_name} added as #{role}." }
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to person_path(@person), alert: "Could not add relationship: #{e.message}"
    end
  end

  def destroy
    family_member = FamilyMember.find(params[:id])
    family = family_member.family
    family_member.destroy

    # Clean up empty families
    family.destroy if family.family_members.empty?

    respond_to do |format|
      format.html { redirect_to person_path(@person), notice: "Relationship removed." }
      format.turbo_stream { redirect_to person_path(@person), notice: "Relationship removed." }
    end
  end

  private

  def set_person
    @person = Person.find(params[:person_id])
  end

  def person_params
    params.require(:person).permit(:first_name, :last_name, :gender, :birth_date, :birth_place)
  end

  def add_parent(parent)
    # Find or create the family where @person is a child
    child_family = @person.family_members.where(role: :child).first&.family
    child_family ||= Family.create!

    # Add @person as child if not already
    FamilyMember.find_or_create_by!(person: @person, family: child_family, role: :child)

    # Add parent with appropriate role
    parent_role = parent.female? ? :mother : :father
    FamilyMember.create!(person: parent, family: child_family, role: parent_role)
  end

  def add_spouse(spouse)
    # Create a new family unit for this couple
    family = Family.create!
    self_role = @person.female? ? :mother : :father
    spouse_role = spouse.female? ? :mother : :father

    FamilyMember.create!(person: @person, family: family, role: self_role)
    FamilyMember.create!(person: spouse, family: family, role: spouse_role)
  end

  def add_child(child)
    # Find or create a family where @person is a parent
    parent_role = @person.female? ? :mother : :father
    parent_family = @person.family_members.where(role: [:father, :mother]).first&.family
    parent_family ||= Family.create!

    FamilyMember.find_or_create_by!(person: @person, family: parent_family, role: parent_role)
    FamilyMember.create!(person: child, family: parent_family, role: :child)
  end
end
