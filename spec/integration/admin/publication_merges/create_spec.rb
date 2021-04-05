require 'integration/integration_spec_helper'
require 'integration/admin/shared_examples_for_admin_page'

feature "managing duplicate publication groups", type: :feature do
  let!(:group) { create :duplicate_publication_group }

  before { authenticate_admin_user }

  context "a group with no publications" do
    before { visit rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id) }

    describe "clicking the 'Delete Group' button" do
      it "deletes the group" do
        click_on "Delete Group"
        expect { group.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "redirects to the group list" do
        click_on "Delete Group"
        expect(page.current_path).to eq rails_admin.index_path(model_name: :duplicate_publication_group)
      end
    end
  end

  context "a group with one publication" do
    let!(:pub) { create :publication, duplicate_group: group }
    let!(:import) { create :publication_import, publication: pub }
    before { visit rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id) }

    describe "clicking the 'Delete Group' button" do
      it "deletes the group" do
        click_on "Delete Group"
        expect { group.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "redirects to the group list" do
        click_on "Delete Group"
        expect(page.current_path).to eq rails_admin.index_path(model_name: :duplicate_publication_group)
      end
    end
  end

  context "a group with three publications" do
    let!(:pub1) { create :publication, duplicate_group: group }
    let!(:pub1_import1) { create :publication_import, publication: pub1 }
    let!(:pub2) { create :publication, duplicate_group: group }
    let!(:pub2_import1) { create :publication_import, publication: pub2 }
    let!(:pub2_import2) { create :publication_import, publication: pub2 }
    let!(:pub3) { create :publication, duplicate_group: group }
    let!(:pub3_import1) { create :publication_import, publication: pub3 }
    before do
      visit rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      click_on "Merge Selected"
    end

    context "trying to merge without selecting anything" do
      it "redirects back to the group" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      end

      it "shows an error message" do
        expect(page).to have_content I18n.t('admin.publication_merges.create.missing_params_error')
      end

      it "doesn't change the group" do
        expect(group.reload.publications).to match_array [pub1, pub2, pub3]
      end

      it "doesn't change the publications" do
        expect(pub1.reload.imports).to eq [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to eq [pub3_import1]
      end
    end

    context "trying to merge without selecting a merge target" do
      before do
        check "selected_publication_ids_#{pub1.id}"
        click_on "Merge Selected"
      end

      it "redirects back to the group" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      end

      it "shows an error message" do
        expect(page).to have_content I18n.t('admin.publication_merges.create.missing_params_error')
      end

      it "doesn't change the group" do
        expect(group.reload.publications).to match_array [pub1, pub2, pub3]
      end

      it "doesn't change the publications" do
        expect(pub1.reload.imports).to eq [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to eq [pub3_import1]
      end
    end

    context "trying to merge without selecting any publications" do
      before do
        choose "merge_target_publication_id_#{pub1.id}"
        click_on "Merge Selected"
      end

      it "redirects back to the group" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      end

      it "shows an error message" do
        expect(page).to have_content I18n.t('admin.publication_merges.create.missing_params_error')
      end

      it "doesn't change the group" do
        expect(group.reload.publications).to match_array [pub1, pub2, pub3]
      end

      it "doesn't change the publications" do
        expect(pub1.reload.imports).to eq [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to eq [pub3_import1]
      end
    end

    context "selecting the same publication as the chosen merge target and merging" do
      before do
        choose "merge_target_publication_id_#{pub1.id}"
        check "selected_publication_ids_#{pub1.id}"
        click_on "Merge Selected"
      end

      it "redirects back to the group" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      end

      it "doesn't change the group" do
        expect(group.reload.publications).to match_array [pub1, pub2, pub3]
      end

      it "doesn't change the publications" do
        expect(pub1.reload.imports).to eq [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to eq [pub3_import1]
      end
    end

    context "choosing one publication as the merge target and selecting another publication to merge" do
      before do
        choose "merge_target_publication_id_#{pub1.id}"
        check "selected_publication_ids_#{pub2.id}"
        click_on "Merge Selected"
      end

      it "redirects back to the group" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      end

      it "shows a success message" do
        expect(page).to have_content I18n.t('admin.publication_merges.create.merge_success')
      end

      it "deletes the merged publication" do
        expect { pub2.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "reassigns the merged publication's imports" do
        expect(pub1.reload.imports).to match_array [pub1_import1, pub2_import1, pub2_import2]
      end

      it "doesn't change the unselected publication" do
        expect(pub3.reload.imports).to eq [pub3_import1]
      end

      it "leaves the group containing the correct publications" do
        expect(group.reload.publications).to match_array [pub1, pub3]
      end
    end

    context "choosing one publication as the merge target and selecting another publication that's in the same non-duplicate group to merge" do
      let(:ndpg) { create :non_duplicate_publication_group }

      before do
        create :non_duplicate_publication_group_membership,
                publication: pub1,
                non_duplicate_group: ndpg
        create :non_duplicate_publication_group_membership,
                publication: pub2,
                non_duplicate_group: ndpg
        
        choose "merge_target_publication_id_#{pub1.id}"
        check "selected_publication_ids_#{pub2.id}"
        click_on "Merge Selected"
      end

      it "redirects back to the group and displays modal" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
        expect(page).to have_content('Override Known Non-Duplicates?')
      end

      describe 'cancelling the merge' do
        before do
          click_on 'Cancel'
        end

        it 'redirects to the duplicate group edit page without merging' do
          expect(page.current_path).to eq Rails.application.routes.url_helpers.admin_duplicate_publication_group_path(group.id)
        end

        it "doesn't delete the selected publication" do
          expect { pub2.reload }.not_to raise_error
        end

        it "does not reassign the merged publication's imports" do
          expect(pub1.reload.imports).to match_array [pub1_import1]
          expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        end

        it "doesn't change the unselected publication" do
          expect(pub3.reload.imports).to eq [pub3_import1]
        end

        it "doesn't change the contents of the duplicate group" do
          expect(group.reload.publications).to match_array [pub1, pub2, pub3]
        end
      end

      describe 'overriding and removing the non duplicate group' do
        before do
          click_on 'Continue'
        end

        it "redirects back to the group" do
          expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
        end

        it "shows a success message" do
          expect(page).to have_content I18n.t('admin.publication_merges.create.merge_success')
        end

        it "deletes the merged publication" do
          expect { pub2.reload }.to raise_error ActiveRecord::RecordNotFound
        end

        it "reassigns the merged publication's imports" do
          expect(pub1.reload.imports).to match_array [pub1_import1, pub2_import1, pub2_import2]
        end

        it "doesn't change the unselected publication" do
          expect(pub3.reload.imports).to eq [pub3_import1]
        end

        it "leaves the group containing the correct publications" do
          expect(group.reload.publications).to match_array [pub1, pub3]
        end

        it "deletes the non-duplicate group" do
          expect { ndpg.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    context "choosing one publication as the merge target and selecting two other publications to merge who are in a non-duplicate group" do
      let(:ndpg) { create :non_duplicate_publication_group }

      before do
        create :non_duplicate_publication_group_membership,
               publication: pub2,
               non_duplicate_group: ndpg
        create :non_duplicate_publication_group_membership,
               publication: pub3,
               non_duplicate_group: ndpg

        choose "merge_target_publication_id_#{pub1.id}"
        check "selected_publication_ids_#{pub2.id}"
        check "selected_publication_ids_#{pub3.id}"
        click_on "Merge Selected"
      end

      describe 'overriding and removing the non duplicate group' do
        before do
          click_on 'Continue'
        end

        it "redirects back to the group" do
          expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
        end

        it "shows a success message" do
          expect(page).to have_content I18n.t('admin.publication_merges.create.merge_success')
        end

        it "deletes the merged publications" do
          expect { pub2.reload }.to raise_error ActiveRecord::RecordNotFound
          expect { pub3.reload }.to raise_error ActiveRecord::RecordNotFound
        end

        it "reassigns the merged publication's imports" do
          expect(pub1.reload.imports).to match_array [pub1_import1, pub2_import1, pub2_import2, pub3_import1]
        end

        it "leaves the group containing the correct publications" do
          expect(group.reload.publications).to match_array [pub1]
        end

        it "deletes the non-duplicate group" do
          expect { ndpg.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    context "choosing one publication as the merge target and selecting both the merge target and another publication to merge" do
      before do
        choose "merge_target_publication_id_#{pub1.id}"
        check "selected_publication_ids_#{pub1.id}"
        check "selected_publication_ids_#{pub2.id}"
        click_on "Merge Selected"
      end

      it "redirects back to the group" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      end

      it "shows a success message" do
        expect(page).to have_content I18n.t('admin.publication_merges.create.merge_success')
      end

      it "deletes the merged publication" do
        expect { pub2.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "reassigns the merged publication's imports" do
        expect(pub1.reload.imports).to match_array [pub1_import1, pub2_import1, pub2_import2]
      end

      it "doesn't change the unselected publication" do
        expect(pub3.reload.imports).to eq [pub3_import1]
      end

      it "leaves the group containing the correct publications" do
        expect(group.reload.publications).to match_array [pub1, pub3]
      end
    end

    context "selecting one publication to ignore" do
      before do
        check "selected_publication_ids_#{pub1.id}"
        click_on "Ignore Selected"
      end

      it "redirects back to the group" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      end

      it "shows an error message" do
        expect(page).to have_content I18n.t('admin.publication_merges.create.too_few_pubs_to_ignore_error')
      end
    end

    context "selecting two publications to ignore" do
      before do
        check "selected_publication_ids_#{pub1.id}"
        check "selected_publication_ids_#{pub2.id}"
        click_on "Ignore Selected"
      end

      it "removes the selected publications from the duplicate group" do
        expect(group.reload.publications).to eq [pub3]
      end

      it "creates a new non-duplicate group with the selected publications" do
        g = NonDuplicatePublicationGroup.last
        expect(g.publications).to match_array [pub1, pub2]
      end

      it "redirects back to the group" do
        expect(page.current_path).to eq rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
      end

      it "shows a success message" do
        expect(page).to have_content I18n.t('admin.publication_merges.create.ignore_success')
      end
    end
  end
end
