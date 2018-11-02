require 'integration/integration_spec_helper'
require 'integration/admin/shared_examples_for_admin_page'

feature "Admin user detail page", type: :feature do
  let!(:user) { create(:user, first_name: 'Bob',
                       last_name: 'Testuser',
                       webaccess_id: 'bat123',
                       activity_insight_identifier: 'ai12345',
                       pure_uuid: 'pure67890',
                       penn_state_identifier: 'psu345678') }

  let!(:pub1) { create :publication, title: "Bob's First Publication",
                       journal_title: "First Journal",
                       publisher: "First Publisher",
                       published_on: Date.new(2017, 1, 1) }

  let!(:pub2) { create :publication, title: "Bob's Second Publication",
                       journal_title: "Second Journal",
                       publisher: "Second Publisher",
                       published_on: Date.new(2018, 1, 1),
                       duplicate_group: group }

  let!(:pres1) { create :presentation, title: "Bob's First Presentation" }
  let!(:pres2) { create :presentation, name: "Bob's Second Presentation" }

  let(:group) { create :duplicate_publication_group }

  let(:org1) { create :organization, name: "Test Org One" }
  let(:org2) { create :organization, name: "Test Org Two" }

  let(:con1) { create :contract, title: "Test Contract One"}
  let(:con2) { create :contract, title: "Test Contract Two"}

  let(:etd1) { create :etd, title: "Test ETD One" }
  let(:etd2) { create :etd, title: "Test ETD Two" }

  context "when the current user is an admin" do
    before do
      authenticate_admin_user
      create :authorship, user: user, publication: pub1
      create :authorship, user: user, publication: pub2

      create :presentation_contribution, user: user, presentation: pres1
      create :presentation_contribution, user: user, presentation: pres2

      create :user_organization_membership, user: user, organization: org1
      create :user_organization_membership, user: user, organization: org2

      create :user_contract, user: user, contract: con1
      create :user_contract, user: user, contract: con2

      create :committee_membership, user: user, etd: etd1
      create :committee_membership, user: user, etd: etd2
    end

    describe "the page content" do
      before { visit rails_admin.show_path(model_name: :user, id: user.id) }

      it "shows the user detail heading" do
        expect(page).to have_content "Details for User 'Bob Testuser'"
      end

      it "shows the user's WebAccess ID" do
        expect(page).to have_content 'bat123'
      end

      it "shows the user's Activity Insight ID" do
        expect(page).to have_content 'ai12345'
      end

      it "shows the user's Pure ID" do
        expect(page).to have_content 'pure67890'
      end

      it "shows the user's Penn State ID" do
        expect(page).to have_content 'psu345678'
      end

      it "shows the user's publications" do
        expect(page).to have_link "Bob's First Publication"
        expect(page).to have_content "First Journal"
        expect(page).to have_content "First Publisher"
        expect(page).to have_content "2017"

        expect(page).to have_link "Bob's Second Publication"
        expect(page).to have_content "Second Journal"
        expect(page).to have_content "Second Publisher"
        expect(page).to have_content "2018"
        expect(page).to have_link "Duplicate group ##{group.id}"
      end

      it "shows the user's presentations" do
        expect(page).to have_link "Bob's First Presentation"
        expect(page).to have_link "Bob's Second Presentation"
      end

      it "shows the user's organizations and memberships" do
        expect(page).to have_link "Bob Testuser - Test Org One"
        expect(page).to have_link "Bob Testuser - Test Org Two"

        expect(page).to have_link "Test Org One"
        expect(page).to have_link "Test Org Two"
      end

      it "shows the user's contracts" do
        expect(page).to have_link "Test Contract One"
        expect(page).to have_link "Test Contract Two"
      end

      it "shows the user's ETDs" do
        expect(page).to have_link "Test ETD One"
        expect(page).to have_link "Test ETD Two"
      end
    end

    describe "the page layout" do
      before { visit rails_admin.show_path(model_name: :user, id: user.id) }

      it_behaves_like "a page with the admin layout"
    end
  end

  context "when the current user is not an admin" do
    before { authenticate_user }
    it "redirects back to the home page with an error message" do
      visit rails_admin.show_path(model_name: :user, id: user.id)
      expect(page.current_path).to eq root_path
      expect(page).to have_content I18n.t('admin.authorization.not_authorized')
    end
  end
end
