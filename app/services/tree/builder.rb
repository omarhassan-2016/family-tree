module Tree
  class Builder
    MAX_DEPTH = 100

    def initialize(person, depth: MAX_DEPTH)
      @person = person
      @depth = [depth, MAX_DEPTH].min
      @visited = Set.new
      
      # Preload the graph to eliminate N+1 queries
      preload_graph
    end

    def build
      build_node(@person, @depth)
    end

    private

    def preload_graph
      @people = Person.all.index_by(&:id)
      @memberships_by_person = FamilyMember.all.group_by(&:person_id)
      @memberships_by_family = FamilyMember.all.group_by(&:family_id)
    end

    def get_parents(person)
      memberships = @memberships_by_person[person.id] || []
      child_families = memberships.select(&:child?).map(&:family_id)
      
      parent_ids = child_families.flat_map do |fid|
        (@memberships_by_family[fid] || []).select { |m| m.father? || m.mother? }.map(&:person_id)
      end
      
      parent_ids.uniq.map { |id| @people[id] }.compact
    end

    def get_children(person)
      memberships = @memberships_by_person[person.id] || []
      parent_families = memberships.select { |m| m.father? || m.mother? }.map(&:family_id)
      
      child_ids = parent_families.flat_map do |fid|
        (@memberships_by_family[fid] || []).select(&:child?).map(&:person_id)
      end
      
      child_ids.uniq.map { |id| @people[id] }.compact
    end

    def get_spouses(person)
      memberships = @memberships_by_person[person.id] || []
      parent_families = memberships.select { |m| m.father? || m.mother? }.map(&:family_id)
      
      spouse_ids = parent_families.flat_map do |fid|
        (@memberships_by_family[fid] || []).select { |m| m.father? || m.mother? }.map(&:person_id)
      end
      
      # Remove self
      spouse_ids.reject! { |id| id == person.id }
      
      spouse_ids.uniq.map { |id| @people[id] }.compact
    end

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
        node[:parents] = get_parents(person).map { |p| build_node(p, remaining_depth - 1) }.compact
        node[:spouses] = get_spouses(person).map { |s| build_spouse_node(s) }
        node[:children] = get_children(person).map { |c| build_node(c, remaining_depth - 1) }.compact
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
