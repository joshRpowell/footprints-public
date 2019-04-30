require 'spec_helper'

describe DashboardController do
  let(:repo) { Footprints::Repository }
  let(:confirmed_app)             { repo.applicant.create(name: "Confirmeded App", applied_on: Date.today, email: "test1@test.com",
                                                          assigned_crafter: "A. Crafter", crafter_id: crafter.id, has_steward: true,
                                                          :discipline => "developer", :skill => "resident", :location => "Chicago") }
  let(:not_yet_responded_app)     { repo.applicant.create(name: "NotYetResponded App", applied_on: Date.today, email: "test2@test.com",
                                                          assigned_crafter: "A. Crafter", crafter_id: crafter.id, has_steward: false,
                                                          :discipline => "developer", :skill => "resident", :location => "Chicago") }
  let(:archived_app)              { repo.applicant.create(name: "Archived App", applied_on: Date.today, email: "test3@test.com",
                                                          assigned_crafter: "A. Crafter", crafter_id: crafter.id, has_steward: true,
                                                          :discipline => "developer", :skill => "resident", :location => "Chicago", archived: true) }
  let(:crafter)                 { repo.crafter.create(name: "A. Crafter", employment_id: "123", email: "testcrafter@abcinc.com") }
  let(:current_user)              { repo.user.new({ :login => "A. Crafter", :email => "testuser@abcinc.com"}) }
  let(:assigned_applicant_record) { AssignedCrafterRecord.create(:applicant_id => not_yet_responded_app.id, :crafter_id => crafter.id) }

  it "redirects to login page when not logged in" do
    get :index
    expect(response).to redirect_to(oauth_signin_path)
  end

  it "redirects to login page when logged in but not an employee" do
    controller.stub(:authenticate).and_return(true)
    get :index
    expect(response).to redirect_to(oauth_signin_path)
  end

  context "when logged in and employee" do
    before :each do
      controller.stub(:current_user).and_return(current_user)
      controller.stub(:authenticate)
      controller.stub(:employee?)
      current_user.update_attribute(:crafter_id, crafter.id)
    end

    it "finds correct crafter and his/her applicants for index" do
      get :index
      expect(assigns(:crafter)).to eq(current_user.crafter)
      expect(assigns(:confirmed_applicants)).to eq([confirmed_app])
      expect(assigns(:not_yet_responded_applicants)).to eq([not_yet_responded_app])
    end

    it "successfully displays the page" do
      get :index
      (expect(response.status).to eq(200))
    end

    it "can confirm an applicant assignment" do
      get :confirm_applicant_assignment, { :id => not_yet_responded_app.id }
      expect(assigns(:applicant)).to eq not_yet_responded_app
    end

    it "redirects after confirming an applicant assignment" do
      get :confirm_applicant_assignment, { :id => not_yet_responded_app.id }
      expect(response).to redirect_to(root_path)
    end

    it "can decline an applicant assigment" do
      get :decline_applicant_assignment, { :id => not_yet_responded_app.id }
      expect(assigns(:applicant)).to eq not_yet_responded_app
    end

    it "redirects after sending decline" do
      get :decline_applicant_assignment, { :id => not_yet_responded_app.id }
      expect(response).to redirect_to(root_path)
    end

    it "sets assigned_crafter_records#current to false when an applicant assignment is declined" do
      assigned_applicant_record
      current_records = AssignedCrafterRecord.where(:applicant_id => not_yet_responded_app.id, :crafter_id => crafter.id,
                                                      :current => true)
      expect(current_records.count).to eq(1)
      get :decline_applicant_assignment, {:id => not_yet_responded_app.id}
      expect(current_records.count).to eq(0)
    end

    it "assigned_crafter_records is still current when an applicant assignment is confirmed" do
      record = assigned_applicant_record
      current_records = AssignedCrafterRecord.where(:applicant_id => not_yet_responded_app.id, :crafter_id => crafter.id,
                                                      :current => true)
      expect(current_records.count).to eq(1)
      get :confirm_applicant_assignment, {:id => not_yet_responded_app.id}
      expect(current_records.count).to eq(1)
    end

    it "can decline all applicants" do
      assigned_applicant_record
      current_records = AssignedCrafterRecord.where(:applicant_id => not_yet_responded_app.id, :crafter_id => crafter.id,
                                                      :current => true)
      expect(current_records.count).to eq(1)
      post :decline_all_applicants
      expect(current_records.count).to eq(0)
    end

    it "redirects after declining all applicants" do
      post :decline_all_applicants
      expect(response).to redirect_to(root_path)
    end

    it "sets the date until which the crafter is unavailable for new applicants" do
      assigned_applicant_record

      post :decline_all_applicants, { :unavailable_until => "08/06/2014" }
      expect(current_user.crafter.unavailable_until).to eq Date.parse("08/06/2014")
    end

    it "does not set the Crafter's unavailability if there are no applicants to decline" do
      post :decline_all_applicants, { :unavailable_until => "08/06/2014" }
      expect(current_user.crafter.unavailable_until).to eq nil
    end

    it 'raises an exception when the date is in the past' do
      assigned_applicant_record

      post :decline_all_applicants, { :unavailable_until => "08/06/2013" }
      expect(flash[:error].first).to eq "Date must be in the future"
    end
  end
end
