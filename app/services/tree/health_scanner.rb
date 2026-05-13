module Tree
  class HealthScanner
    # Scans the entire family tree for anomalies and warnings
    # Returns a hash of arrays categorized by severity/type.
    def self.scan
      issues = []

      Person.find_each do |person|
        # 1. Invalid Lifespan (Death before birth)
        if person.birth_date && person.death_date && person.death_date < person.birth_date
          issues << build_issue(person, :critical, "Death before birth", "Recorded death date is before birth date.")
        end

        # 2. Extreme Lifespan (> 110 years)
        if person.age && person.age > 110
          issues << build_issue(person, :warning, "Unlikely lifespan", "Person is recorded as living #{person.age} years (over 110).")
        end

        # 3. Missing expected birth dates (dead people should ideally have birth dates)
        if person.death_date.present? && person.birth_date.nil?
          issues << build_issue(person, :info, "Missing birth date", "Person has a death date but no birth date.")
        end

        # Relationship anomalies
        person.children.each do |child|
          next unless child.birth_date && person.birth_date

          # 4. Parent too young (< 13 years old at child's birth)
          age_at_birth = child.birth_date.year - person.birth_date.year
          if age_at_birth < 13
            issues << build_issue(person, :critical, "Parent too young", "Was only #{age_at_birth} years old when child #{child.full_name} was born.", related: child)
          end

          # 5. Parent too old (Mother > 55, Father > 80)
          if person.female? && age_at_birth > 55
            issues << build_issue(person, :warning, "Mother unusually old", "Was #{age_at_birth} years old when child #{child.full_name} was born.", related: child)
          elsif person.male? && age_at_birth > 80
            issues << build_issue(person, :warning, "Father unusually old", "Was #{age_at_birth} years old when child #{child.full_name} was born.", related: child)
          end

          # 6. Child born after parent's death
          if person.death_date
            months_after_death = (child.birth_date.year * 12 + child.birth_date.month) - (person.death_date.year * 12 + person.death_date.month)
            if person.female? && months_after_death > 0
              issues << build_issue(person, :critical, "Child born after mother's death", "Child #{child.full_name} born after mother's death.", related: child)
            elsif person.male? && months_after_death > 9
              issues << build_issue(person, :critical, "Child born >9 months after father's death", "Child #{child.full_name} born #{months_after_death} months after father's death.", related: child)
            end
          end
        end

        # Family / Marriage anomalies
        person.families.each do |family|
          next unless family.marriage_date && person.birth_date

          age_at_marriage = family.marriage_date.year - person.birth_date.year

          # 7. Marriage before birth
          if family.marriage_date < person.birth_date
            issues << build_issue(person, :critical, "Marriage before birth", "Marriage date is before person's birth date.", related_family: family)
          end

          # 8. Marriage at very young age
          if age_at_marriage > 0 && age_at_marriage < 14
            issues << build_issue(person, :warning, "Married very young", "Was #{age_at_marriage} years old at marriage.", related_family: family)
          end
        end
      end

      # Group issues by severity
      {
        critical: issues.select { |i| i[:severity] == :critical },
        warning: issues.select { |i| i[:severity] == :warning },
        info: issues.select { |i| i[:severity] == :info }
      }
    end

    private

    def self.build_issue(person, severity, title, message, related: nil, related_family: nil)
      {
        person: person,
        severity: severity,
        title: title,
        message: message,
        related: related,
        related_family: related_family
      }
    end
  end
end
