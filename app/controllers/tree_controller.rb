class TreeController < ApplicationController
  def show
    @person = Person.find(params[:person_id])
    @tree_data = Tree::Builder.new(@person, depth: 3).build

    respond_to do |format|
      format.html
      format.json { render json: @tree_data }
    end
  end

  def link
    require_contributor
    
    source = Person.find(params[:source_id])
    target = Person.find(params[:target_id])
    relation_type = params[:relation_type]

    begin
      case relation_type
      when 'parent'
        add_parent(source, target)
      when 'child'
        add_child(source, target)
      when 'spouse'
        add_spouse(source, target)
      end
      render json: { success: true }
    rescue => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def add_parent(child, parent)
    child_family = child.family_members.where(role: :child).first&.family
    child_family ||= Family.create!
    FamilyMember.find_or_create_by!(person: child, family: child_family, role: :child)
    parent_role = parent.female? ? :mother : :father
    FamilyMember.create!(person: parent, family: child_family, role: parent_role)
  end

  def add_child(parent, child)
    parent_role = parent.female? ? :mother : :father
    parent_family = parent.family_members.where(role: [:father, :mother]).first&.family
    parent_family ||= Family.create!
    FamilyMember.find_or_create_by!(person: parent, family: parent_family, role: parent_role)
    FamilyMember.create!(person: child, family: parent_family, role: :child)
  end

  def add_spouse(person1, person2)
    family = Family.create!
    role1 = person1.female? ? :mother : :father
    role2 = person2.female? ? :mother : :father
    FamilyMember.create!(person: person1, family: family, role: role1)
    FamilyMember.create!(person: person2, family: family, role: role2)
  end
end
