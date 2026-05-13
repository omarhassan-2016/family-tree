module Gedcom
  class Exporter
    def export
      lines = []
      lines.concat(header_lines)
      lines.concat(submitter_lines)

      Person.find_each do |person|
        lines.concat(person_lines(person))
      end

      Family.includes(family_members: :person).find_each do |family|
        lines.concat(family_lines(family))
      end

      lines << "0 TRLR"
      lines.join("\r\n") + "\r\n"
    end

    private

    def header_lines
      [
        "0 HEAD",
        "1 SOUR FamilyTreeBuilder",
        "2 VERS 1.0",
        "2 NAME Family Tree Builder",
        "1 DEST DISK",
        "1 DATE #{Date.today.strftime('%d %b %Y').upcase}",
        "1 SUBM @SUBM1@",
        "1 GEDC",
        "2 VERS 5.5.1",
        "2 FORM LINEAGE-LINKED",
        "1 CHAR UTF-8"
      ]
    end

    def submitter_lines
      [
        "0 @SUBM1@ SUBM",
        "1 NAME Family Tree Builder User"
      ]
    end

    def person_lines(person)
      xref = person.gedcom_id || "@I#{person.id}@"
      lines = ["0 #{xref} INDI"]

      # NAME
      last = person.last_name.present? ? "/#{person.last_name}/" : "//"
      lines << "1 NAME #{person.first_name} #{last}".strip

      # SEX
      sex = case person.gender
            when "male" then "M"
            when "female" then "F"
            else "U"
            end
      lines << "1 SEX #{sex}"

      # BIRT
      if person.birth_date || person.birth_place.present?
        lines << "1 BIRT"
        lines << "2 DATE #{format_date(person.birth_date)}" if person.birth_date
        lines << "2 PLAC #{person.birth_place}" if person.birth_place.present?
      end

      # DEAT
      if person.death_date || person.death_place.present?
        lines << "1 DEAT"
        lines << "2 DATE #{format_date(person.death_date)}" if person.death_date
        lines << "2 PLAC #{person.death_place}" if person.death_place.present?
      end

      # NOTE
      lines << "1 NOTE #{person.notes}" if person.notes.present?

      lines
    end

    def family_lines(family)
      xref = family.gedcom_id || "@F#{family.id}@"
      lines = ["0 #{xref} FAM"]

      family.family_members.each do |fm|
        person_xref = fm.person.gedcom_id || "@I#{fm.person.id}@"
        case fm.role
        when "father" then lines << "1 HUSB #{person_xref}"
        when "mother" then lines << "1 WIFE #{person_xref}"
        when "child"  then lines << "1 CHIL #{person_xref}"
        end
      end

      if family.marriage_date || family.marriage_place.present?
        lines << "1 MARR"
        lines << "2 DATE #{format_date(family.marriage_date)}" if family.marriage_date
        lines << "2 PLAC #{family.marriage_place}" if family.marriage_place.present?
      end

      lines
    end

    def format_date(date)
      date.strftime("%d %b %Y").upcase
    end
  end
end
