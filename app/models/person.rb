class Person < ApplicationRecord
  has_many :family_members, dependent: :destroy
  has_many :families, through: :family_members

  enum :gender, { male: 0, female: 1, unknown: 2 }

  validates :first_name, presence: true

  # --- Derived Relationship Accessors ---

  def parents
    Person.joins(:family_members)
          .where(family_members: { family_id: families_as_child.select(:id),
                                   role: [FamilyMember.roles[:father], FamilyMember.roles[:mother]] })
          .distinct
  end

  def children
    Person.joins(:family_members)
          .where(family_members: { family_id: families_as_parent.select(:id),
                                   role: FamilyMember.roles[:child] })
          .distinct
  end

  def spouses
    Person.joins(:family_members)
          .where(family_members: { family_id: families_as_parent.select(:id),
                                   role: [FamilyMember.roles[:father], FamilyMember.roles[:mother]] })
          .where.not(id: id)
          .distinct
  end

  def siblings
    Person.joins(:family_members)
          .where(family_members: { family_id: families_as_child.select(:id),
                                   role: FamilyMember.roles[:child] })
          .where.not(id: id)
          .distinct
  end

  # --- Search ---

  scope :search, ->(query) {
    return none if query.blank?
    sanitized = sanitize_sql_like(query)
    where("first_name ILIKE :q OR last_name ILIKE :q OR CONCAT(first_name, ' ', last_name) ILIKE :q",
          q: "%#{sanitized}%")
  }

  # --- Display Helpers ---

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def life_span
    parts = []
    parts << birth_date.year.to_s if birth_date
    parts << death_date.year.to_s if death_date
    parts.any? ? parts.join(" – ") : nil
  end

  private

  def families_as_child
    Family.joins(:family_members)
          .where(family_members: { person_id: id, role: FamilyMember.roles[:child] })
  end

  def families_as_parent
    Family.joins(:family_members)
          .where(family_members: { person_id: id,
                                   role: [FamilyMember.roles[:father], FamilyMember.roles[:mother]] })
  end
end
