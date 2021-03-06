require File.dirname(__FILE__) + '/../spec_helper'

describe Users::RegistrationsController, "create" do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end
  it "should create a user" do
    u = User.make
    lambda {
      post :create, :user => {:login => u.login, :password => "zomgbar", :password_confirmation => "zomgbar", :email => u.email}
    }.should change(User, :count).by(1)
  end

  it "should return json about the user" do
    u = User.make
    post :create, :format => :json, :user => {
      :login => u.login, 
      :password => "zomgbar", 
      :password_confirmation => "zomgbar", 
      :email => u.email
    }
    lambda {
      json = JSON.parse(response.body)
    }.should_not raise_error
  end

  it "should not return the password" do
    u = User.make
    post :create, :format => :json, :user => {
      :login => u.login, 
      :password => "zomgbar", 
      :password_confirmation => "zomgbar", 
      :email => u.email
    }
    response.body.should_not =~ /zomgbar/
  end

  it "should show errors when invalid" do
    post :create, :format => :json, :user => {
      :password => "zomgbar", 
      :password_confirmation => "zomgbar"
    }
    json = JSON.parse(response.body)
    json['errors'].should_not be_blank
  end
end
