class Family < ApplicationRecord
  has_many :family_members, dependent: :destroy
  has_many :people, through: :family_members

  def father
    people_by_role(:father).first
  end

  def mother
    people_by_role(:mother).first
  end

  def children
    people_by_role(:child)
  end

  def parents
    people_by_role(:father) + people_by_role(:mother)
  end

  private

  def people_by_role(role)
    people.where(family_members: { role: FamilyMember.roles[role] })
  end
end
