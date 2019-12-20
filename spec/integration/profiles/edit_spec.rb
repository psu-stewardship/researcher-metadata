require 'integration/integration_spec_helper'
require 'integration/profiles/shared_examples_for_profile_management_page'

describe "editing profile preferences" do
  let!(:user) { create :user,
                       webaccess_id: 'abc123',
                       first_name: 'Bob',
                       last_name: 'Testuser',
                       show_all_publications: true,
                       orcid_identifier: orcid_id }
  let!(:other_user) { create :user, webaccess_id: 'xyz789'}
  let!(:pub_1) { create :publication,
                        title: "Bob's Publication",
                        visible: true,
                        journal_title: "The Journal",
                        published_on: Date.new(2007, 1, 1) }
  let!(:pub_2) { create :publication,
                        title: "Bob's Other Publication",
                        visible: false }
  let!(:pub_3) { create :publication,
                        title: "Bob's Open Access Publication",
                        visible: true,
                        open_access_url: "https://example.org/pubs/1" }
  let!(:pub_4) { create :publication,
                        title: "Bob's Other Open Access Publication",
                        visible: true,
                        user_submitted_open_access_url: "https://example.org/pubs/2" }
  let!(:pub_5) { create :publication,
                        title: "Bob's Non-Open Access Publication",
                        visible: true }
  let!(:pub_6) { create :publication,
                        title: "Bob's Pending ScholarSphere Publication",
                        visible: true }
  let!(:auth_1) { create :authorship, publication: pub_1, user: user, visible_in_profile: false }
  let!(:auth_2) { create :authorship, publication: pub_2, user: user, visible_in_profile: false }
  let!(:auth_3) { create :authorship, publication: pub_3, user: user, visible_in_profile: false }
  let!(:auth_4) { create :authorship, publication: pub_4, user: user, visible_in_profile: false }
  let!(:auth_5) { create :authorship, publication: pub_5, user: user, visible_in_profile: false }
  let!(:auth_6) { create :authorship,
                         publication: pub_6,
                         user: user,
                         visible_in_profile: false,
                         scholarsphere_uploaded_at: Time.current }
  let!(:waiver) { create :internal_publication_waiver, authorship: auth_5 }
  let!(:pres1) { create :presentation,
                        title: "Bob's Presentation",
                        organization: "Penn State",
                        location: "University Park, PA",
                        visible: true }
  let!(:pres2) { create :presentation,
                        title: "Bob's Other Presentation",
                        visible: false }
  let!(:cont_1) { create :presentation_contribution,
                         presentation: pres1,
                         user: user,
                         visible_in_profile: false }
  let!(:cont_2) { create :presentation_contribution,
                         presentation: pres2,
                         user: user,
                         visible_in_profile: false }
  let!(:perf_1) { create :performance,
                         title: "Bob's Performance",
                         location: "University Park, PA",
                         start_on: Date.new(2000, 1, 1),
                         visible: true }
  let!(:perf_2) { create :performance,
                         title: "Bob's Other Performance",
                         visible: true }
  let!(:up_1) { create :user_performance,
                       performance: perf_1,
                       user: user }
  let!(:up_2) { create :user_performance,
                       performance: perf_2,
                       user: user }
  let(:orcid_id) { nil }

  feature "the manage profile link", type: :feature do
    describe "visiting the profile page for a given user" do
      context "when not logged in" do
        before { visit profile_path(webaccess_id: 'abc123') }

        it "does not display a link to manage the profile" do
          expect(page).to_not have_link "Manage my profile"
        end
      end
      context "when logged in as that user" do
        before do
          authenticate_as(user)
          visit profile_path(webaccess_id: 'abc123')
        end

        it "displays a link to manage the profile" do
          expect(page).to have_link "Manage my profile", href: edit_profile_publications_path
        end
      end
      context "when logged in as a different user" do
        before do
          authenticate_as(other_user)
          visit profile_path(webaccess_id: 'abc123')
        end

        it "does not display a link to manage the profile" do
          expect(page).to_not have_link "Manage my profile"
        end
      end
    end
  end

  feature "the ORCID link", type: :feature do
    describe "visiting the profile page for a given user" do
      context "when not logged in" do
        before { visit profile_path(webaccess_id: 'abc123') }

        context "when the user has no ORCID ID" do
          it "does not display an ORCID ID link" do
            expect(page).to_not have_link "ORCID iD"
          end

          it "does not display an ORCID call to action" do
            expect(page).to_not have_link "Link my ORCID ID"
          end
        end
        context "when the user has an ORCID ID" do
          let(:orcid_id) { 'https://orcid.org/my-orcid-id' }

          it "displays an ORCID ID link" do
            expect(page).to have_link "ORCID iD", href: 'https://orcid.org/my-orcid-id'
          end

          it "does not display an ORCID call to action" do
            expect(page).to_not have_link "Link my ORCID ID"
          end
        end
      end
      context "when logged in as that user" do
        before do
          authenticate_as(user)
          visit profile_path(webaccess_id: 'abc123')
        end

        context "when the user has no ORCID ID" do
          it "does not display an ORCID ID link" do
            expect(page).to_not have_link "ORCID iD"
          end

          it "does displays an ORCID call to action" do
            expect(page).to have_link "Link my ORCID ID", href: 'https://guides.libraries.psu.edu/orcid'
          end
        end
        context "when the user has an ORCID ID" do
          let(:orcid_id) { 'https://orcid.org/my-orcid-id' }

          it "displays an ORCID ID link" do
            expect(page).to have_link "ORCID iD", href: 'https://orcid.org/my-orcid-id'
          end

          it "does not display an ORCID call to action" do
            expect(page).to_not have_link "Link my ORCID ID"
          end
        end
      end
      context "when logged in as a different user" do
        before do
          authenticate_as(other_user)
          visit profile_path(webaccess_id: 'abc123')
        end

        context "when the user has no ORCID ID" do
          it "does not display an ORCID ID link" do
            expect(page).to_not have_link "ORCID iD"
          end

          it "does not display an ORCID call to action" do
            expect(page).to_not have_link "Link my ORCID ID"
          end
        end
        context "when the user has an ORCID ID" do
          let(:orcid_id) { 'https://orcid.org/my-orcid-id' }

          it "displays an ORCID ID link" do
            expect(page).to have_link "ORCID iD", href: 'https://orcid.org/my-orcid-id'
          end

          it "does not display an ORCID call to action" do
            expect(page).to_not have_link "Link my ORCID ID"
          end
        end
      end
    end
  end

  feature "the profile publications edit page" do
    context "when the user is signed in" do
      before do
        authenticate_as(user)
        visit edit_profile_publications_path
      end

      it_behaves_like "a profile management page"

      it "shows the correct heading content" do
        expect(page).to have_content "Manage Profile Publications"
      end

      it "shows descriptions of the user's visible publications" do
        expect(page).to have_content "Bob's Publication, The Journal, 2007"
        expect(page).to have_link "Bob's Publication", href: edit_open_access_publication_path(pub_1)
        expect(page).to_not have_content "Bob's Other Publication"
        expect(page).to have_content "Bob's Open Access Publication"
        expect(page).not_to have_link "Bob's Open Access Publication"
        expect(page).to have_content "Bob's Other Open Access Publication"
        expect(page).not_to have_link "Bob's Other Open Access Publication"
        expect(page).to have_content "Bob's Non-Open Access Publication"
        expect(page).not_to have_link "Bob's Non-Open Access Publication"
        expect(page).to have_content "Bob's Pending ScholarSphere Publication"
        expect(page).not_to have_link "Bob's Pending ScholarSphere Publication"
      end

      it "shows an icon to indicate when we don't have open access information for a publication" do
        within "tr#authorship_#{auth_1.id}" do
          expect(page).to have_css '.fa-question'
        end
      end

      it "shows an icon to indicate when we have an open access URL for a publication" do
        within "tr#authorship_#{auth_3.id}" do
          expect(page).to have_css '.fa-unlock-alt'
        end

        within "tr#authorship_#{auth_4.id}" do
          expect(page).to have_css '.fa-unlock-alt'
        end
      end

      it "shows an icon to indicate when open access obligations have been waived for a publication" do
        within "tr#authorship_#{auth_5.id}" do
          expect(page).to have_css '.fa-lock'
        end
      end

      it "shows an icon to indicate when a publication is being added to ScholarSphere" do
        within "tr#authorship_#{auth_6.id}" do
          expect(page).to have_css '.fa-hourglass-half'
        end
      end

      it "shows a link to submit a waiver for a publication that is outside of the system" do
        expect(page).to have_link "here", href: new_external_publication_waiver_path
      end
    end
    
    context "when the user is not signed in" do
      before { visit edit_profile_publications_path }

      it "does not allow the user to visit the page" do
        expect(page.current_path).not_to eq edit_profile_publications_path
      end
    end
  end

  feature "the profile presentations edit page" do
    context "when the user is signed in" do
      before do
        authenticate_as(user)
        visit edit_profile_presentations_path
      end

      it_behaves_like "a profile management page"

      it "shows the correct heading content" do
        expect(page).to have_content "Manage Profile Presentations"
      end

      it "shows descriptions of the user's visible presentations" do
        expect(page).to have_content "Bob's Presentation - Penn State - University Park, PA"
        expect(page).to_not have_content "Bob's Other Presentation - -"
      end
    end

    context "when the user is not signed in" do
      before { visit edit_profile_presentations_path }

      it "does not allow the user to visit the page" do
        expect(page.current_path).not_to eq edit_profile_presentations_path
      end
    end
  end

  feature "the profile performances edit page" do
    context "when the user is signed in" do
      before do
        authenticate_as(user)
        visit edit_profile_performances_path
      end

      it_behaves_like "a profile management page"

      it "shows the correct heading content" do
        expect(page).to have_content "Manage Profile Performances"
      end

      it "shows descriptions of the user's visible performances" do
        expect(page).to have_content "Bob's Performance - University Park, PA - 2000-01-01"
        expect(page).to_not have_content "Bob's Other Performance - -"
      end
    end

    context "when the user is not signed in" do
      before { visit edit_profile_performances_path }

      it "does not allow the user to visit the page" do
        expect(page.current_path).not_to eq edit_profile_performances_path
      end
    end
  end

  describe "the path /profile" do
    before do
      authenticate_as(user)
      visit 'profile'
    end

    it "redirects to the profile publications edit page" do
      expect(page.current_path).to eq edit_profile_publications_path
    end
  end
end
