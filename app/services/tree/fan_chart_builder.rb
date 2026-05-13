module Tree
  class FanChartBuilder
    MAX_GENERATIONS = 5

    def initialize(person, generations: MAX_GENERATIONS)
      @person = person
      @generations = [generations, MAX_GENERATIONS].min
    end

    # Build ancestor data for a radial fan chart.
    # Returns nested structure: { person: ..., father: { person:..., father:..., mother:... }, mother: ... }
    def build
      build_ancestor_node(@person, @generations)
    end

    # Returns a flat array of arcs for the SVG fan chart
    # Each arc has: generation, position, person data, start_angle, end_angle
    def build_arcs
      arcs = []
      root = build

      # Root (generation 0) — full circle center
      arcs << {
        generation: 0,
        position: 0,
        person: person_data(root[:person]),
        start_angle: 0,
        end_angle: 360
      }

      # Build arcs for each generation
      collect_arcs(root, 1, 0, 360, arcs)
      arcs
    end

    private

    def build_ancestor_node(person, depth)
      return nil if person.nil?

      node = { person: person }

      if depth > 0
        parents = person.parents.to_a
        father = parents.find { |p| p.male? }
        mother = parents.find { |p| p.female? } || parents.find { |p| p != father }

        node[:father] = build_ancestor_node(father, depth - 1)
        node[:mother] = build_ancestor_node(mother, depth - 1)
      end

      node
    end

    def collect_arcs(node, generation, start_angle, end_angle, arcs)
      return if generation > @generations

      half = (end_angle - start_angle) / 2.0

      # Father (first half)
      if node[:father]
        arcs << {
          generation: generation,
          position: arcs.count { |a| a[:generation] == generation },
          person: person_data(node[:father][:person]),
          start_angle: start_angle,
          end_angle: start_angle + half
        }
        collect_arcs(node[:father], generation + 1, start_angle, start_angle + half, arcs)
      else
        arcs << {
          generation: generation,
          position: arcs.count { |a| a[:generation] == generation },
          person: nil,
          start_angle: start_angle,
          end_angle: start_angle + half
        }
      end

      # Mother (second half)
      if node[:mother]
        arcs << {
          generation: generation,
          position: arcs.count { |a| a[:generation] == generation },
          person: person_data(node[:mother][:person]),
          start_angle: start_angle + half,
          end_angle: end_angle
        }
        collect_arcs(node[:mother], generation + 1, start_angle + half, end_angle, arcs)
      else
        arcs << {
          generation: generation,
          position: arcs.count { |a| a[:generation] == generation },
          person: nil,
          start_angle: start_angle + half,
          end_angle: end_angle
        }
      end
    end

    def person_data(person)
      return nil unless person
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
