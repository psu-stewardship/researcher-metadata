require 'integration/integration_spec_helper'
require 'integration/admin/shared_examples_for_admin_page'

feature "Admin journal detail page", type: :feature do
  let!(:journal) { create :journal,
                          title: 'Test Journal',
                          pure_uuid: 'pure-abc-123' }

  context "when the current user is an admin" do
    before { authenticate_admin_user }

    describe "the page content" do
      before { visit rails_admin.show_path(model_name: :journal, id: journal.id) }

      it "shows the journal detail heading" do
        expect(page).to have_content "Details for Journal 'Test Journal'"
      end

      it "shows the journal's Pure UUID" do
        expect(page).to have_content "pure-abc-123"
      end
    end

    describe "the page layout" do
      before { visit rails_admin.show_path(model_name: :journal, id: journal.id) }

      it_behaves_like "a page with the admin layout"
    end
  end

  context "when the current user is not an admin" do
    before { authenticate_user }
    it "redirects back to the home page with an error message" do
      visit rails_admin.show_path(model_name: :journal, id: journal.id)
      expect(page.current_path).to eq root_path
      expect(page).to have_content I18n.t('admin.authorization.not_authorized')
    end
  end
end
