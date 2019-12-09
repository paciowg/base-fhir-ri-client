class DashboardController < ApplicationController
  def index
    pat_param = params[:patient]
    redirect_to :root && return if pat_param.blank?

    patients = Rails.cache.read("patients")
    if patients.nil?
      @patient = SessionHandler.fhir_client(session.id).read(FHIR::Patient, pat_param).resource
    else
      @patient = patients.select{ |patient| patient.id.eql?(pat_param) }.first
    end

    redirect_to :root && return if @patient.blank?

    patient_name = @patient.name.select{ |name| name.use.eql?("official") }.first

    @patient_name_first = patient_name.given.first
    @patient_name_middle = patient_name.given[1..-1].join(" ")
    @patient_name_middle ||= ""
    @patient_name_last = patient_name.family
  end
end
