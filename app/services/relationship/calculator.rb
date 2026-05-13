module Relationship
  class Calculator
    # Computes how person_a is related to person_b using BFS on the family graph.
    # Returns a hash with :path (array of person IDs), :description (human-readable string),
    # and :steps (array of step descriptions).
    def initialize(person_a, person_b)
      @person_a = person_a
      @person_b = person_b
    end

    def calculate
      return { path: [@person_a.id], description: "Same person", steps: [] } if @person_a.id == @person_b.id

      result = bfs(@person_a, @person_b)
      return nil unless result

      path_people = result[:path].map { |id| Person.find(id) }
      steps = build_steps(path_people, result[:edges])
      description = describe_relationship(result[:edges])

      {
        path: result[:path],
        path_people: path_people,
        edges: result[:edges],
        steps: steps,
        description: description,
        distance: result[:edges].size
      }
    end

    private

    # BFS finding the shortest path between two people
    # Edges are labeled with the relationship type: :parent, :child, :spouse, :sibling
    def bfs(start, target)
      queue = [[start.id, [], []]] # [current_id, path_of_ids, edge_labels]
      visited = Set.new([start.id])

      while queue.any?
        current_id, path, edges = queue.shift
        current = Person.find(current_id)

        neighbors = get_neighbors(current)
        neighbors.each do |neighbor_id, edge_type|
          next if visited.include?(neighbor_id)

          new_path = path + [current_id]
          new_edges = edges + [edge_type]

          if neighbor_id == target.id
            return { path: new_path + [neighbor_id], edges: new_edges }
          end

          visited.add(neighbor_id)
          queue << [neighbor_id, new_path, new_edges]
        end

        # Safety: don't traverse the entire database
        return nil if visited.size > 500
      end

      nil
    end

    # Get all immediate relatives of a person with edge labels
    def get_neighbors(person)
      neighbors = []

      person.parents.pluck(:id).each { |id| neighbors << [id, :parent] }
      person.children.pluck(:id).each { |id| neighbors << [id, :child] }
      person.spouses.pluck(:id).each { |id| neighbors << [id, :spouse] }
      person.siblings.pluck(:id).each { |id| neighbors << [id, :sibling] }

      neighbors
    end

    # Build human-readable step descriptions
    def build_steps(path_people, edges)
      steps = []
      edges.each_with_index do |edge, i|
        from = path_people[i]
        to = path_people[i + 1]
        arrow = case edge
                when :parent then "⬆️ parent of"
                when :child then "⬇️ child of"
                when :spouse then "💍 spouse of"
                when :sibling then "👫 sibling of"
                end
        steps << { from: from, to: to, label: arrow, edge: edge }
      end
      steps
    end

    # Describe the overall relationship in human terms
    def describe_relationship(edges)
      return "Unknown relationship" if edges.empty?

      # Direct relationships
      if edges.size == 1
        case edges[0]
        when :parent then return "Parent"
        when :child then return "Child"
        when :spouse then return "Spouse"
        when :sibling then return "Sibling"
        end
      end

      # Two-step relationships
      if edges.size == 2
        pair = edges.map(&:to_s).join("-")
        case pair
        when "parent-parent" then return "Grandparent"
        when "child-child" then return "Grandchild"
        when "parent-sibling" then return "Uncle / Aunt"
        when "sibling-child" then return "Nephew / Niece"
        when "parent-spouse" then return "Step-parent"
        when "spouse-child" then return "Step-child"
        when "parent-child" then return "Sibling (half)"
        when "sibling-spouse" then return "Sibling-in-law"
        when "spouse-sibling" then return "Sibling-in-law"
        when "spouse-parent" then return "Parent-in-law"
        when "child-spouse" then return "Child-in-law"
        when "sibling-sibling" then return "Sibling"
        end
      end

      # Three-step relationships
      if edges.size == 3
        triple = edges.map(&:to_s).join("-")
        case triple
        when "parent-parent-parent" then return "Great-grandparent"
        when "child-child-child" then return "Great-grandchild"
        when "parent-sibling-child" then return "Cousin"
        when "parent-parent-sibling" then return "Great-uncle / Great-aunt"
        when "parent-parent-child" then return "Uncle / Aunt (half)"
        end
      end

      # Four-step
      if edges.size == 4
        quad = edges.map(&:to_s).join("-")
        if quad == "parent-parent-sibling-child"
          return "Second Cousin (once removed)"
        elsif quad == "parent-sibling-child-child"
          return "Cousin (once removed)"
        elsif quad == "parent-parent-parent-parent"
          return "Great-great-grandparent"
        elsif quad == "child-child-child-child"
          return "Great-great-grandchild"
        end
      end

      # Generic fallback: count generations up and down
      ups = edges.count(:parent)
      downs = edges.count(:child)
      spouse_links = edges.count(:spouse)
      sibling_links = edges.count(:sibling)

      parts = []
      parts << "#{ups}× ancestor" if ups > 0
      parts << "#{downs}× descendant" if downs > 0
      parts << "by marriage" if spouse_links > 0
      parts << "via sibling" if sibling_links > 0

      parts.any? ? "Relative (#{parts.join(', ')})" : "Distant relative"
    end
  end
end
