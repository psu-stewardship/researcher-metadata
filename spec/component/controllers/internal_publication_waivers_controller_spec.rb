require 'component/component_spec_helper'

describe InternalPublicationWaiversController, type: :controller do
  let!(:user) { create :user }
  let!(:other_user) { create :user }
  let!(:pub) { create :publication }
  let!(:oa_pub) { create :publication, open_access_url: "url" }
  let!(:uoa_pub) { create :publication, user_submitted_open_access_url: "url" }
  let!(:other_pub) { create :publication }
  let!(:uploaded_pub) { create :publication }
  let!(:other_uploaded_pub) { create :publication }
  let!(:auth) { create :authorship, user: user, publication: pub }
  let!(:waived_pub) { create :publication }
  let!(:other_waived_pub) { create :publication }
  let!(:auth) { create :authorship, user: user, publication: pub }
  let!(:waived_auth) { create :authorship, user: user, publication: waived_pub}
  let!(:other_waived_auth) { create :authorship, user: other_user, publication: other_waived_pub}
  let!(:uploaded_auth) { create :authorship, user: user, publication: uploaded_pub }
  let!(:other_uploaded_auth) { create :authorship, user: other_user, publication: other_uploaded_pub }

  before do
    create :authorship, user: user, publication: oa_pub
    create :authorship, user: user, publication: uoa_pub
    create :authorship,
           user: user,
           publication: other_uploaded_pub
    create :authorship,
           user: user,
           publication: other_waived_pub

    create :scholarsphere_work_deposit, authorship: uploaded_auth, status: 'Pending'
    create :scholarsphere_work_deposit, authorship: other_uploaded_auth, status: 'Pending'

    create :internal_publication_waiver,
           authorship: waived_auth
    create :internal_publication_waiver,
           authorship: other_waived_auth
  end

  describe '#new' do
    context "when not authenticated" do
      it "redirects to the home page" do
        get :new, params: {id: 1}

        expect(response).to redirect_to root_path
      end

      it "sets a flash error message" do
        get :new, params: {id: 1}

        expect(flash[:alert]).to eq I18n.t('devise.failure.unauthenticated')
      end
    end

    context "when authenticated" do
      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context "when given the ID for a publication that does not belong to the user" do
        it "returns 404" do
          expect { get :new, params: {id: other_pub.id} }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context "when given the ID for a publication that belongs to the user and has an open access URL" do
        it "redirects to the read-only view of the publication's open access status" do
          get :new, params: {id: oa_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(oa_pub)
        end
      end

      context "when given the ID for a publication that belongs to the user and has a user-submitted open access URL" do
        it "redirects to the read-only view of the publication's open access status" do
          get :new, params: {id: uoa_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(uoa_pub)
        end
      end

      context "when given the ID for a publication that has already been uploaded to ScholarSphere by the user" do
        it "redirects to the read-only view of the publication's open access status" do
          get :new, params: {id: uploaded_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(uploaded_pub)
        end
      end

      context "when given the ID for a publication that has already been uploaded to ScholarSphere by another user" do
        it "redirects to the read-only view of the publication's open access status" do
          get :new, params: {id: other_uploaded_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(other_uploaded_pub)
        end
      end

      context "when given the ID for a publication for which the user has waived open access" do
        it "redirects to the read-only view of the publication's open access status" do
          get :new, params: {id: waived_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(waived_pub)
        end
      end

      context "when given the ID for a publication for which another user has waived open access" do
        it "redirects to the read-only view of the publication's open access status" do
          get :new, params: {id: other_waived_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(other_waived_pub)
        end
      end

      context "when given the ID for a publication that belongs to the user and is not open access" do          
        it "returns 200 OK" do
          get :new, params: {id: pub.id}
          expect(response.code).to eq "200"
        end
      end
    end
  end

  describe '#create' do
    context "when not authenticated" do
      it "redirects to the home page" do
        get :new, params: {id: 1}

        expect(response).to redirect_to root_path
      end

      it "sets a flash error message" do
        get :new, params: {id: 1}

        expect(flash[:alert]).to eq I18n.t('devise.failure.unauthenticated')
      end
    end

    context "when authenticated" do
      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context "when given the ID for a publication that does not belong to the user" do
        it "returns 404" do
          expect { post :create, params: {id: other_pub.id} }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context "when given the ID for a publication that belongs to the user and has an open access URL" do
        it "redirects to the read-only view of the publication's open access status" do
          post :create, params: {id: oa_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(oa_pub)
        end
      end

      context "when given the ID for a publication that belongs to the user and has a user-submitted open access URL" do
        it "redirects to the read-only view of the publication's open access status" do
          post :create, params: {id: uoa_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(uoa_pub)
        end
      end

      context "when given the ID for a publication that has already been uploaded to ScholarSphere by the user" do
        it "redirects to the read-only view of the publication's open access status" do
          post :create, params: {id: uploaded_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(uploaded_pub)
        end
      end

      context "when given the ID for a publication that has already been uploaded to ScholarSphere by another user" do
        it "redirects to the read-only view of the publication's open access status" do
          post :create, params: {id: other_uploaded_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(other_uploaded_pub)
        end
      end

      context "when given the ID for a publication for which the user has waived open access" do
        it "redirects to the read-only view of the publication's open access status" do
          post :create, params: {id: waived_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(waived_pub)
        end
      end

      context "when given the ID for a publication for which another user has waived open access" do
        it "redirects to the read-only view of the publication's open access status" do
          post :create, params: {id: other_waived_pub.id}
          expect(response).to redirect_to edit_open_access_publication_path(other_waived_pub)
        end
      end

      context "when given the ID for a publication that belongs to the user and is not open access" do
        context "when not given the required params" do          
          it "raises an error" do
            expect { post :create, params: {id: pub.id} }.to raise_error ActionController::ParameterMissing
          end
        end
        context "when given the required params" do          
          it "redirects to the publication list" do
            post :create, params: {id: pub.id, internal_publication_waiver: {reason_for_waiver: 'reason'}}
            expect(response).to redirect_to edit_profile_publications_path
          end
        end
      end
    end
  end
end
