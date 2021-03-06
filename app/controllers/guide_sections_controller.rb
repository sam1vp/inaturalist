class GuideSectionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_required
  before_filter :load_record, :only => [:show, :edit, :update, :destroy]

  # GET /guide_sections
  # GET /guide_sections.json
  def index
    @guide_sections = GuideSection.scoped
    @guide_sections = @guide_sections.where("id IN (?)", params[:ids]) unless params[:ids].blank?

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => {:guide_sections => @guide_sections.as_json(:root => false)} }
    end
  end

  # GET /guide_sections/1
  # GET /guide_sections/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @guide_section.as_json(:root => true) }
    end
  end

  # GET /guide_sections/new
  # GET /guide_sections/new.json
  def new
    @guide_section = GuideSection.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @guide_section.as_json(:root => true) }
    end
  end

  # GET /guide_sections/1/edit
  def edit
  end

  # POST /guide_sections
  # POST /guide_sections.json
  def create
    @guide_section = GuideSection.new(params[:guide_section])

    respond_to do |format|
      if @guide_section.save
        format.html { redirect_to @guide_section, notice: 'Guide section was successfully created.' }
        format.json { render json: @guide_section, status: :created, location: @guide_section }
      else
        format.html { render action: "new" }
        format.json { render json: @guide_section.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /guide_sections/1
  # PUT /guide_sections/1.json
  def update
    respond_to do |format|
      if @guide_section.update_attributes(params[:guide_section])
        format.html { redirect_to @guide_section, notice: 'Guide section was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @guide_section.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /guide_sections/1
  # DELETE /guide_sections/1.json
  def destroy
    @guide_section = GuideSection.find(params[:id])
    @guide_section.destroy

    respond_to do |format|
      format.html { redirect_to guide_sections_url }
      format.json { head :no_content }
    end
  end

  def import
    provider = params[:provider].to_s.downcase
    @sections = if provider == "eol"
      import_from_eol
    else
      import_from_wikipedia
    end
    @sections = (@sections || []).sort_by(&:title)
    respond_to do |format|
      format.json do
        render :json => @sections
      end
    end
  end

  def import_from_eol
    eol = EolService.new(:timeout => 10)
    pages = eol.search(params[:q], :exact => true)
    id = pages.at('entry/id').try(:content)
    return unless id
    page = eol.page(id, :text => 50, :subjects => "all", :details => true)
    page.remove_namespaces!
    TaxonDescribers::Eol.data_objects_from_page(page).to_a.uniq.map do |data_object|
      GuideSection.new(
        :title => (data_object.at('title') || data_object.at('subject')).content.split('#').last.underscore.humanize,
        :description => data_object.at('description').content
      )
    end
  rescue Timeout::Error => e
    []
  end

  def import_from_wikipedia
    w = WikipediaService.new(:debug => true)
    r = w.parse(:page => params[:q], :prop => "sections")
    return [] if r.at('error')
    r.search('s').map do |s|
      sr = w.parse(:page => s['fromtitle'], :section => s['index'], :noimages => 1, :disablepp => 1)
      next if s.at('error')
      txt = Nokogiri::HTML(sr.at('text').inner_text).search('p').to_s.strip
      next if txt.blank?
      GuideSection.new(
        :title => s['line'],
        :description => txt
      )
    end.compact
  end
end
