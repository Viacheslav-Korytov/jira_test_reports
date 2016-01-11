class LastReportsController < ApplicationController
  before_action :set_last_report, only: [:show, :edit, :update, :destroy]

  # GET /last_reports
  # GET /last_reports.json
  def index
    @last_reports = LastReport.all
  end

  # GET /last_reports/1
  # GET /last_reports/1.json
  def show
  end

  # GET /last_reports/new
  def new
    @last_report = LastReport.new
  end

  # GET /last_reports/1/edit
  def edit
  end

  # POST /last_reports
  # POST /last_reports.json
  def create
    @last_report = LastReport.new(last_report_params)

    respond_to do |format|
      if @last_report.save
        format.html { redirect_to @last_report, notice: 'Last report was successfully created.' }
        format.json { render action: 'show', status: :created, location: @last_report }
      else
        format.html { render action: 'new' }
        format.json { render json: @last_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /last_reports/1
  # PATCH/PUT /last_reports/1.json
  def update
    respond_to do |format|
      if @last_report.update(last_report_params)
        format.html { redirect_to @last_report, notice: 'Last report was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @last_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /last_reports/1
  # DELETE /last_reports/1.json
  def destroy
    @last_report.destroy
    respond_to do |format|
      format.html { redirect_to last_reports_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_last_report
      @last_report = LastReport.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def last_report_params
      params.require(:last_report).permit(:issue, :total, :passed, :failed, :inprogress, :p_executed, :p_passed)
    end
end
