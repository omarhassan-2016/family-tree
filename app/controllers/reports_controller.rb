class ReportsController < ApplicationController
  def show
    @person = Person.find(params[:person_id])
    pdf = Reports::PersonPdf.new(@person)

    send_data pdf.render,
              filename: "#{@person.full_name.parameterize}_report.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end
end
