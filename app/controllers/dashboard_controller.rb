class DashboardController < ApplicationController
  def show
    @total_people = Person.count
    @total_families = Family.count
    @recent_people = Person.order(updated_at: :desc).limit(8)

    # --- Statistics ---
    @male_count = Person.male.count
    @female_count = Person.female.count
    @unknown_count = Person.unknown.count

    # Births by decade
    @births_by_decade = Person.where.not(birth_date: nil)
      .group("(EXTRACT(YEAR FROM birth_date)::int / 10) * 10")
      .order(Arel.sql("(EXTRACT(YEAR FROM birth_date)::int / 10) * 10"))
      .count

    # Top surnames
    @top_surnames = Person.where.not(last_name: [nil, ""])
      .group(:last_name)
      .order("count_all DESC")
      .limit(8)
      .count

    # Average lifespan (people with both birth and death dates)
    lifespans = Person.where.not(birth_date: nil, death_date: nil).pluck(:birth_date, :death_date)
    if lifespans.any?
      ages = lifespans.map { |b, d| ((d - b).to_f / 365.25).round }
      @avg_lifespan = (ages.sum.to_f / ages.size).round(1)
      @max_lifespan = ages.max
      @min_lifespan = ages.min
    end

    # Living vs deceased
    @living_count = Person.where(death_date: nil).count
    @deceased_count = Person.where.not(death_date: nil).count

    # Earliest and latest
    @earliest_birth = Person.where.not(birth_date: nil).minimum(:birth_date)
    @latest_marriage = Family.maximum(:marriage_date)
  end
end
