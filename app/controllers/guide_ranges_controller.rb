class GuideRangesController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]
  before_filter :admin_required
  before_filter :load_record, :only => [:show, :edit, :update, :destroy]

  # GET /guide_ranges
  # GET /guide_ranges.json
  def index
    @guide_ranges = GuideRange.scoped
    @guide_ranges = @guide_ranges.where("id IN (?)", params[:ids]) unless params[:ids].blank?

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => {:guide_ranges => @guide_ranges.as_json(:root => false)} }
    end
  end

  # GET /guide_ranges/1
  # GET /guide_ranges/1.json
  def show
    @guide_range = GuideRange.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @guide_range.as_json(:root => true) }
    end
  end

  # GET /guide_ranges/new
  # GET /guide_ranges/new.json
  def new
    @guide_range = GuideRange.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @guide_range.as_json(:root => true) }
    end
  end

  # GET /guide_ranges/1/edit
  def edit
    @guide_range = GuideRange.find(params[:id])
  end

  # POST /guide_ranges
  # POST /guide_ranges.json
  def create
    @guide_range = GuideRange.new(params[:guide_range])

    respond_to do |format|
      if @guide_range.save
        format.html { redirect_to @guide_range, notice: 'Guide range was successfully created.' }
        format.json { render json: @guide_range.as_json(:root => true), status: :created, location: @guide_range }
      else
        format.html { render action: "new" }
        format.json { render json: @guide_range.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /guide_ranges/1
  # PUT /guide_ranges/1.json
  def update
    @guide_range = GuideRange.find(params[:id])

    respond_to do |format|
      if @guide_range.update_attributes(params[:guide_range])
        format.html { redirect_to @guide_range, notice: 'Guide range was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @guide_range.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /guide_ranges/1
  # DELETE /guide_ranges/1.json
  def destroy
    @guide_range = GuideRange.find(params[:id])
    @guide_range.destroy

    respond_to do |format|
      format.html { redirect_to guide_ranges_url }
      format.json { head :no_content }
    end
  end
end
