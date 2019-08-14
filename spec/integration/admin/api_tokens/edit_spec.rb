require 'integration/integration_spec_helper'
require 'integration/admin/shared_examples_for_admin_page'

feature "Admin API token edit page", type: :feature do
  let!(:token) { create :api_token,
                        app_name: "Test Application",
                        admin_email: 'admin123@psu.edu' }

  context "when the current user is an admin" do
    before do
      authenticate_admin_user
      visit rails_admin.edit_path(model_name: :api_token, id: token.id)
    end

    describe "visiting the form to edit an API Token" do
      it_behaves_like "a page with the admin layout"
      it "show the correct content" do
        expect(page).to have_content "Edit API token"
      end

      it "does not allow the token's value to be set" do
        expect(page).not_to have_field 'Token'
      end

      it "does not allow the token's total requests to be set" do
        expect(page).not_to have_field 'Total requests'
      end
    end

    describe "submitting the form to update an API Token" do
      before do
        fill_in 'App name', with: 'Updated'
        fill_in 'Admin email', with: 'test@email.com'

        click_button 'Save'
      end

      it "saves the new API Token data" do
        t = token.reload
        expect(t.token).not_to be_blank
        expect(t.app_name).to eq 'Updated'
        expect(t.admin_email).to eq 'test@email.com'
        expect(t.total_requests).to eq 0
      end
    end
  end

  context "when the current user is not an admin" do
    before { authenticate_user }
    it "redirects back to the home page with an error message" do
      visit rails_admin.edit_path(model_name: :api_token, id: token.id)
      expect(page.current_path).to eq root_path
      expect(page).to have_content I18n.t('admin.authorization.not_authorized')
    end
  end
end