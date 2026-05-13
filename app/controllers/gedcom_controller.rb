class GedcomController < ApplicationController
  def new
  end

  def create
    unless params[:file].present?
      redirect_to new_gedcom_path, alert: "Please select a GEDCOM file to import."
      return
    end

    # Read as binary to preserve raw bytes — the importer handles encoding detection
    content = File.binread(params[:file].tempfile.path)
    importer = Gedcom::Importer.new(content)

    begin
      stats = importer.import!
      redirect_to people_path, notice: "Successfully imported #{stats[:people]} people and #{stats[:families]} families."
    rescue => e
      redirect_to new_gedcom_path, alert: "Import failed: #{e.message}"
    end
  end

  def export
    content = Gedcom::Exporter.new.export
    send_data content,
              filename: "family_tree_#{Date.today.iso8601}.ged",
              type: "text/x-gedcom",
              disposition: "attachment"
  end
end
