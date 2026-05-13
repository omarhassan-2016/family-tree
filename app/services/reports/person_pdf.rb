module Reports
  class PersonPdf
    include Prawn::View

    COLORS = {
      primary: "4338CA",
      secondary: "6366F1",
      text: "1F2937",
      muted: "6B7280",
      border: "E5E7EB",
      male: "3B82F6",
      female: "EC4899",
      header_bg: "F3F4F6"
    }.freeze

    def initialize(person)
      @person = person
      @parents = person.parents.to_a
      @children = person.children.to_a
      @spouses = person.spouses.to_a
      @siblings = person.siblings.to_a
      @timeline = person.timeline_events

      build_pdf
    end

    def document
      @document ||= Prawn::Document.new(
        page_size: "A4",
        margin: [50, 50, 50, 50],
        info: {
          Title: "#{@person.full_name} — Family Report",
          Author: "Family Tree Builder",
          Creator: "Family Tree Builder",
          CreationDate: Time.current
        }
      )
    end

    private

    def build_pdf
      header_section
      personal_details_section
      timeline_section if @timeline.any?
      relationships_section
      footer_section
    end

    def header_section
      # Title bar
      fill_color COLORS[:primary]
      fill_rectangle [bounds.left, cursor], bounds.width, 60
      fill_color "FFFFFF"
      draw_text @person.full_name, at: [15, cursor - 25], size: 22, style: :bold
      subtitle = [@person.gender.humanize, @person.life_span].compact.join(" · ")
      draw_text subtitle, at: [15, cursor - 45], size: 11
      fill_color COLORS[:text]

      move_down 75

      # Report metadata
      font_size(9) do
        fill_color COLORS[:muted]
        text "Generated on #{Date.today.strftime('%B %d, %Y')} by Family Tree Builder", align: :right
        fill_color COLORS[:text]
      end

      move_down 10
      stroke_color COLORS[:border]
      stroke_horizontal_rule
      move_down 15
    end

    def personal_details_section
      section_title("Personal Details")

      data = [
        ["First Name", @person.first_name, "Last Name", @person.last_name || "—"],
        ["Gender", @person.gender.humanize, "Age", @person.age ? "#{@person.age} years" : "—"],
        ["Birth Date", @person.birth_date&.strftime("%B %d, %Y") || "—", "Birth Place", @person.birth_place || "—"],
        ["Death Date", @person.death_date&.strftime("%B %d, %Y") || "—", "Death Place", @person.death_place || "—"]
      ]

      if @person.maiden_name.present?
        data << ["Maiden Name", @person.maiden_name, "", ""]
      end

      table(data, width: bounds.width) do |t|
        t.cells.borders = [:bottom]
        t.cells.border_color = COLORS[:border]
        t.cells.padding = [6, 8]
        t.cells.size = 9
        t.column(0).font_style = :bold
        t.column(0).text_color = COLORS[:muted]
        t.column(2).font_style = :bold
        t.column(2).text_color = COLORS[:muted]
        t.column(0).width = 80
        t.column(2).width = 80
      end

      if @person.notes.present?
        move_down 10
        font_size(9) do
          fill_color COLORS[:muted]
          text "Notes:", style: :bold
          fill_color COLORS[:text]
          text @person.notes
        end
      end

      move_down 20
    end

    def timeline_section
      section_title("Life Timeline")

      @timeline.each do |event|
        font_size(9) do
          formatted_text [
            { text: "#{event[:year]}  ", styles: [:bold], color: COLORS[:secondary] },
            { text: "#{event[:label]}", styles: [:bold], color: COLORS[:text] },
            { text: event[:detail].present? ? "  —  #{event[:detail]}" : "", color: COLORS[:muted] }
          ]
          move_down 4
        end
      end

      move_down 15
    end

    def relationships_section
      relationship_table("Parents", @parents)
      relationship_table("Spouses / Partners", @spouses)
      relationship_table("Children", @children)
      relationship_table("Siblings", @siblings)
    end

    def relationship_table(title, people)
      section_title(title)

      if people.empty?
        font_size(9) do
          fill_color COLORS[:muted]
          text "No #{title.downcase} recorded"
          fill_color COLORS[:text]
        end
        move_down 15
        return
      end

      data = [["Name", "Gender", "Birth", "Death", "Place"]]
      people.each do |p|
        data << [
          p.full_name,
          p.gender.humanize,
          p.birth_date&.strftime("%Y") || "—",
          p.death_date&.strftime("%Y") || "—",
          p.birth_place || "—"
        ]
      end

      table(data, width: bounds.width, header: true) do |t|
        t.cells.borders = [:bottom]
        t.cells.border_color = COLORS[:border]
        t.cells.padding = [5, 6]
        t.cells.size = 9
        t.row(0).font_style = :bold
        t.row(0).background_color = COLORS[:header_bg]
        t.row(0).text_color = COLORS[:muted]
      end

      move_down 15
    end

    def section_title(text)
      fill_color COLORS[:secondary]
      font_size(13) do
        text_box text, at: [0, cursor], width: bounds.width, style: :bold
      end
      fill_color COLORS[:text]
      move_down 20
      stroke_color COLORS[:border]
      stroke_horizontal_rule
      move_down 10
    end

    def footer_section
      repeat(:all) do
        bounding_box([bounds.left, bounds.bottom + 25], width: bounds.width, height: 20) do
          font_size(7) do
            fill_color COLORS[:muted]
            text_box "Family Tree Builder  ·  #{@person.full_name}  ·  Page #{page_number}",
                     at: [0, 10], width: bounds.width, align: :center
          end
        end
      end
    end
  end
end
