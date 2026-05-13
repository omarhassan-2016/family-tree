module Tree
  class Builder
    MAX_DEPTH = 3

    def initialize(person, depth: MAX_DEPTH)
      @person = person
      @depth = [depth, MAX_DEPTH].min
      @visited = Set.new
    end

    def build
      build_node(@person, @depth)
    end

    private

    def build_node(person, remaining_depth)
      return nil if person.nil? || @visited.include?(person.id)
      @visited.add(person.id)

      node = {
        id: person.id,
        name: person.full_name,
        gender: person.gender,
        birth_year: person.birth_date&.year,
        death_year: person.death_date&.year,
        birth_place: person.birth_place
      }

      if remaining_depth > 0
        node[:parents] = person.parents.map { |p| build_node(p, remaining_depth - 1) }.compact
        node[:spouses] = person.spouses.map { |s| build_spouse_node(s) }
        node[:children] = person.children.map { |c| build_node(c, remaining_depth - 1) }.compact
      else
        node[:parents] = []
        node[:spouses] = []
        node[:children] = []
      end

      node
    end

    def build_spouse_node(person)
      return nil if person.nil?
      {
        id: person.id,
        name: person.full_name,
        gender: person.gender,
        birth_year: person.birth_date&.year,
        death_year: person.death_date&.year
      }
    end
  end
end
