class GuideTaxaController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]
  before_filter :admin_required
  before_filter :load_record, :only => [:show, :edit, :update, :destroy, :edit_photos, :update_photos]

  # GET /guide_taxa
  # GET /guide_taxa.json
  def index
    @guide_taxa = GuideTaxon.includes(:guide_photos => [:photo]).page(params[:page]).per_page(200)
    @guide_taxa = @guide_taxa.where(:guide_id => params[:guide_id]) unless params[:guide_id].blank?

    respond_to do |format|
      format.html # index.html.erb
      format.json do
        render :json => {:guide_taxa => @guide_taxa.as_json(
          :root => false, 
          :methods => [:guide_photo_ids, :guide_section_ids, :guide_range_ids]
        )}
      end
    end
  end

  # GET /guide_taxa/1
  # GET /guide_taxa/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @guide_taxon.as_json(:root => true,
        :methods => [:guide_photo_ids, :guide_section_ids, :guide_range_ids]) }
    end
  end

  # GET /guide_taxa/new
  # GET /guide_taxa/new.json
  def new
    @guide_taxon = GuideTaxon.new(params[:guide_taxon])
    @guide = @guide_taxon.guide

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @guide_taxon.as_json(:root => true) }
    end
  end

  # GET /guide_taxa/1/edit
  def edit
    @guide = @guide_taxon.guide
  end

  # POST /guide_taxa
  # POST /guide_taxa.json
  def create
    @guide_taxon = GuideTaxon.new(params[:guide_taxon])

    respond_to do |format|
      if @guide_taxon.save
        format.html { redirect_to edit_guide_path(@guide_taxon.guide_id), notice: 'Guide taxon was successfully created.' }
        format.json { render json: @guide_taxon.as_json(:root => true), status: :created, location: @guide_taxon }
      else
        format.html { render action: "new" }
        format.json { render json: @guide_taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /guide_taxa/1
  # PUT /guide_taxa/1.json
  def update
    respond_to do |format|
      if @guide_taxon.update_attributes(params[:guide_taxon])
        format.html { redirect_to edit_guide_taxon_path(@guide_taxon), notice: 'Guide taxon was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @guide_taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /guide_taxa/1
  # DELETE /guide_taxa/1.json
  def destroy
    @guide_taxon.destroy

    respond_to do |format|
      format.html { redirect_to edit_guide_url(@guide_taxon.guide_id) }
      format.json { head :no_content }
    end
  end

  def edit_photos
    @resource = @guide_taxon
    @photos = @guide_taxon.guide_photos.sort_by{|tp| tp.id}.map{|tp| tp.photo}
    render :layout => false, :template => "taxa/edit_photos"
  end

  def update_photos
      photos = retrieve_photos
      errors = photos.map do |p|
        p.valid? ? nil : p.errors.full_messages
      end.flatten.compact
      @guide_taxon.photos = photos
      @guide_taxon.save
      if errors.blank?
        flash[:notice] = "Taxon photos updated!"
      else
        flash[:error] = "Some of those photos couldn't be saved: #{errors.to_sentence.downcase}"
      end
      redirect_to edit_guide_taxon_path(@guide_taxon)
  rescue Errno::ETIMEDOUT
    flash[:error] = "Request timed out!"
    redirect_back_or_default(edit_guide_taxon_path(@guide_taxon))
  rescue Koala::Facebook::APIError => e
    raise e unless e.message =~ /OAuthException/
    flash[:error] = "Facebook needs the owner of that photo to re-confirm their connection to #{CONFIG.site_name_short}."
    redirect_back_or_default(edit_guide_taxon_path(@guide_taxon))
  end

  private
  def retrieve_photos
    photo_classes = Photo.descendent_classes
    photos = []
    photo_classes.each do |photo_class|
      param = photo_class.to_s.underscore.pluralize
      next if params[param].blank?
      params[param].reject {|i| i.blank?}.uniq.each do |photo_id|
        if fp = photo_class.find_by_native_photo_id(photo_id)
          photos << fp 
        elsif photo_class != 'LocalPhoto'
          pp = photo_class.get_api_response(photo_id)
          photos << photo_class.new_from_api_response(pp) if pp
        end
      end
    end
    photos
  end
end
