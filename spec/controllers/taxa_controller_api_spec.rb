require File.dirname(__FILE__) + '/../spec_helper'

shared_examples_for "a TaxaController" do
  describe "show" do
    it "should include range kml url" do
      tr = TaxonRange.make!(:url => "http://foo.bar/range.kml")
      get :show, :format => :json, :id => tr.taxon_id
      response_taxon = JSON.parse(response.body)
      response_taxon['taxon_range_kml_url'].should eq tr.kml_url
    end

    describe "with default photo" do
      let(:photo) { 
        Photo.make!(
          "id" => 1576,
          "large_url" => "http://staticdev.inaturalist.org/photos/1576/large.jpg?1369951594",
          "license" => 4,
          "medium_url" => "http://staticdev.inaturalist.org/photos/1576/medium.jpg?1369951594",
          "native_page_url" => "http://localhost:3000/photos/1576",
          "native_photo_id" => "1576",
          "native_username" => "kueda",
          "original_url" => "http://staticdev.inaturalist.org/photos/1576/original.jpg?1369951594",
          "small_url" => "http://staticdev.inaturalist.org/photos/1576/small.jpg?1369951594",
          "square_url" => "http://staticdev.inaturalist.org/photos/1576/square.jpg?1369951594",
          "thumb_url" => "http://staticdev.inaturalist.org/photos/1576/thumb.jpg?1369951594"
        ) 
      }
      let(:taxon_photo) { TaxonPhoto.make!(:photo => photo) }
      let(:taxon) { taxon_photo.taxon }

      it "should include all image url sizes" do
        get :show, :format => :json, :id => taxon.id
        response_taxon = JSON.parse(response.body)
        %w(thumb small medium large).each do |size|
          response_taxon['default_photo']["#{size}_url"].should eq photo.send("#{size}_url")
        end
      end

      it "should include license url" do
        get :show, :format => :json, :id => taxon.id
        response_taxon = JSON.parse(response.body)
        response_taxon['default_photo']['license_url'].should eq photo.license_url
      end
    end
  end
end

describe TaxaController, "oauth authentication" do
  let(:user) { User.make! }
  let(:token) { stub :accessible? => true, :resource_owner_id => user.id }
  before do
    request.env["HTTP_AUTHORIZATION"] = "Bearer xxx"
    controller.stub(:doorkeeper_token) { token }
  end
  it_behaves_like "a TaxaController"
end

describe TaxaController, "devise authentication" do
  let(:user) { User.make! }
  before do
    http_login(user)
  end
  it_behaves_like "a TaxaController"
end
