class FamilyMember < ApplicationRecord
  belongs_to :person
  belongs_to :family

  enum :role, { father: 0, mother: 1, child: 2 }

  validates :role, presence: true
  validates :person_id, uniqueness: { scope: [:family_id, :role],
                                      message: "already has this role in this family" }
end
