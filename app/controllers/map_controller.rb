class MapController < ApplicationController
  def index
    @places_count = Person.where.not(birth_place: [nil, ""]).count +
                    Person.where.not(death_place: [nil, ""]).count
  end

  def data
    markers = []

    Person.where.not(birth_place: [nil, ""]).each do |person|
      markers << {
        id: person.id,
        name: person.full_name,
        place: person.birth_place,
        type: "birth",
        year: person.birth_date&.year,
        gender: person.gender
      }
    end

    Person.where.not(death_place: [nil, ""]).each do |person|
      markers << {
        id: person.id,
        name: person.full_name,
        place: person.death_place,
        type: "death",
        year: person.death_date&.year,
        gender: person.gender
      }
    end

    render json: markers
  end
end
