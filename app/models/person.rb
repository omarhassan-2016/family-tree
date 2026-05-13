class Person < ApplicationRecord
  has_many :family_members, dependent: :destroy
  has_many :families, through: :family_members
  has_many :comments, as: :commentable, dependent: :destroy
  has_one_attached :avatar
  has_rich_text :rich_notes

  enum :gender, { male: 0, female: 1, unknown: 2 }

  validates :first_name, presence: true
  validate :acceptable_avatar

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

  # --- Duplicate Detection ---

  def self.find_potential_duplicates(first_name:, last_name: nil, birth_date: nil)
    return none if first_name.blank?
    sanitized_first = sanitize_sql_like(first_name)
    scope = where("first_name ILIKE ?", "%#{sanitized_first}%")

    if last_name.present?
      sanitized_last = sanitize_sql_like(last_name)
      scope = scope.where("last_name ILIKE ?", "%#{sanitized_last}%")
    end

    scope = scope.where(birth_date: birth_date) if birth_date.present?
    scope.limit(5)
  end

  # --- Export ---
  def self.to_csv
    require "csv"
    attributes = %w[id first_name last_name maiden_name suffix gender birth_date birth_place death_date death_place]

    CSV.generate(headers: true) do |csv|
      csv << attributes.map(&:humanize)

      all.each do |person|
        csv << attributes.map { |attr| person.send(attr) }
      end
    end
  end

  # --- Timeline Events ---

  def timeline_events
    events = []

    events << { date: birth_date, year: birth_date.year, label: "Born", detail: birth_place, icon: "👶", type: "birth" } if birth_date

    # Marriage events from families where this person is a parent
    families_as_parent_records.each do |family|
      next unless family.marriage_date
      spouse = family.people.where.not(id: id).first
      detail = [family.marriage_place, spouse ? "to #{spouse.full_name}" : nil].compact.join(" — ")
      events << { date: family.marriage_date, year: family.marriage_date.year, label: "Married", detail: detail, icon: "💍", type: "marriage" }
    end

    # Children born
    children.each do |child|
      next unless child.birth_date
      events << { date: child.birth_date, year: child.birth_date.year, label: "Child born", detail: child.full_name, icon: "🍼", type: "child" }
    end

    events << { date: death_date, year: death_date.year, label: "Died", detail: death_place, icon: "🕊️", type: "death" } if death_date

    events.sort_by { |e| e[:date] }
  end

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

  def initials
    "#{first_name[0]}#{last_name&.first}".upcase
  end

  def age
    return nil unless birth_date
    end_date = death_date || Date.today
    age = end_date.year - birth_date.year
    age -= 1 if end_date < birth_date + age.years
    age
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

  def families_as_parent_records
    Family.joins(:family_members)
          .where(family_members: { person_id: id,
                                   role: [FamilyMember.roles[:father], FamilyMember.roles[:mother]] })
          .includes(:people)
  end

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.blob.content_type.in?(%w[image/png image/jpeg image/gif image/webp])
      errors.add(:avatar, "must be a PNG, JPEG, GIF, or WebP image")
    end

    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5MB")
    end
  end
end
