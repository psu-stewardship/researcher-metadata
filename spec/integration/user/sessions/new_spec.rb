require 'integration/integration_spec_helper'

describe "signing in as an admin user", :warden_helpers do
  context "when successful" do
    let(:user) { create :user, webaccess_id: 'esd122', is_admin: true }
    before do
      authenticate_as user
      visit rails_admin.dashboard_path
    end
    it "allows us to visit the admin dashboard" do
      expect(page.current_path).to eq rails_admin.dashboard_path
    end
  end
end
