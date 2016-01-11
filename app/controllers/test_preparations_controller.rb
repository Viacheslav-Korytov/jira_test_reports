class TestPreparationsController < ApplicationController
  before_action :set_test_preparation, only: [:show, :edit, :update, :destroy]
  before_action :get_list_of_wi

  # GET /test_preparations
  # GET /test_preparations.json
  def index
    @test_preparations = TestPreparation.all
  end

  # GET /test_preparations/1
  # GET /test_preparations/1.json
  def show
  end

  # GET /test_preparations/new
  def new
    @test_preparation = TestPreparation.new
  end

  # GET /test_preparations/1/edit
  def edit
  end

  # POST /test_preparations
  # POST /test_preparations.json
  def create
    @test_preparation = TestPreparation.new(test_preparation_params)

    respond_to do |format|
      if @test_preparation.save
        format.html { redirect_to test_preparations_path, notice: 'Test preparation was successfully created.' }
        format.json { render action: 'show', status: :created, location: @test_preparation }
      else
        format.html { render action: 'new' }
        format.json { render json: @test_preparation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /test_preparations/1
  # PATCH/PUT /test_preparations/1.json
  def update
    respond_to do |format|
      if @test_preparation.update(test_preparation_params)
        format.html { redirect_to test_preparations_path, notice: 'Test preparation was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @test_preparation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /test_preparations/1
  # DELETE /test_preparations/1.json
  def destroy
    @test_preparation.destroy
    respond_to do |format|
      format.html { redirect_to test_preparations_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_test_preparation
      @test_preparation = TestPreparation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def test_preparation_params
      params.require(:test_preparation).permit(:issue, :tc_plan, :tc_date, :complete_date)
    end
end
