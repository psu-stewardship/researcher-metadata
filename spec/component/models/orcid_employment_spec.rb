require 'component/component_spec_helper'

describe OrcidEmployment do
  let(:membership) { double 'user organization membership',
                            user: user,
                            organization_name: "Test Organization",
                            position_title: "Test Title",
                            started_on: Date.new(1999, 12, 31) }
  let(:user) { double 'user', orcid_access_token: 'the orcid token',
                              authenticated_orcid_identifier: 'the orcid id' }
  subject(:employment) { OrcidEmployment.new(membership) }

  it { is_expected.to respond_to :location }

  describe "#to_json" do
    context "when the given organization membership has an end date" do
      before { allow(membership).to receive(:ended_on).and_return(Date.new(2020, 1, 2)) }

      it "returns a JSON representation of an ORCID employment that includes an end date" do
        expect(employment.to_json).to eq ({
          organization: {
            name: "The Pennsylvania State University",
            address: {
              city: "University Park",
              region: "Pennsylvania",
              country: "US"
            },
            "disambiguated-organization": {
              "disambiguated-organization-identifier": "grid.29857.31",
              "disambiguation-source": "GRID"
            }
          },
          "department-name": "Test Organization",
          "role-title": "Test Title",
          "start-date": {
            year: 1999,
            month: 12,
            day: 31
          },
          "end-date": {
            year: 2020,
            month: 1,
            day: 2
          }
        }.to_json)
      end
    end

    context "when the given organization membership does not have an end date" do
      before { allow(membership).to receive(:ended_on).and_return(nil) }

      it "returns a JSON representation of an ORCID employment that does not include an end date" do
        expect(employment.to_json).to eq ({
          organization: {
            name: "The Pennsylvania State University",
            address: {
              city: "University Park",
              region: "Pennsylvania",
              country: "US"
            },
            "disambiguated-organization": {
              "disambiguated-organization-identifier": "grid.29857.31",
              "disambiguation-source": "GRID"
            }
          },
          "department-name": "Test Organization",
          "role-title": "Test Title",
          "start-date": {
            year: 1999,
            month: 12,
            day: 31
          }
        }.to_json)
      end
    end
  end

  describe "#save!" do
    let(:client) { double 'ORCID API client' }
    let(:response) { double 'ORCID API response' }
    let(:headers) { {"location" => "the_location"} }
    before do
      allow(OrcidAPIClient).to receive(:new).with(employment).and_return client
      allow(client).to receive(:post).and_return(response)
      allow(response).to receive(:headers).and_return(headers)
    end

    context "when the response from the ORCID API is 201" do
      before { allow(response).to receive(:code).and_return 201 }

      it "sets the employment's location attribute with data from the reponse" do
        employment.save!
        expect(employment.location).to eq "the_location"
      end

      it "returns true" do
        expect(employment.save!).to eq true
      end
    end

    context "when the response from the ORCID API is not 201" do
      before { allow(response).to receive(:code).and_return 400 }

      context "when the response contains an invalid token error" do
        before { allow(response).to receive(:to_s).and_return(%{{"error": "invalid_token"}}) }

        it "raises an InvalidToken error" do
          expect { employment.save! }.to raise_error(OrcidEmployment::InvalidToken)
        end
      end

      context "when the response does not contain an invalid token error" do
        before { allow(response).to receive(:to_s).and_return(%{{"error": "something_else"}}) }

        it "raises a FailedRequest error" do
          expect { employment.save! }.to raise_error(OrcidEmployment::FailedRequest)
        end
      end
    end
  end

  describe "#orcid_type" do
    it "returns 'employment'" do
      expect(employment.orcid_type).to eq "employment"
    end
  end

  describe "#user" do
    it "returns the given organizaiton membership's user" do
      expect(employment.user).to eq user
    end
  end

  describe "#access_token" do
    it "returns the orcid access token of the given organization membership's user" do
      expect(employment.access_token).to eq "the orcid token"
    end
  end

  describe "#orcid_id" do
    it "returns the orcid id of the given organization membership's user" do
      expect(employment.orcid_id).to eq "the orcid id"
    end
  end
end
