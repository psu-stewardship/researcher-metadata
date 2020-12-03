require 'component/component_spec_helper'

describe OrcidWork do
  let(:date) { Date.yesterday }
  let(:publication) { double 'publication',
                             title: 'Test Title',
                             publication_type: 'Academic Journal Article',
                             journal_title: 'Test Journal',
                             publisher_name: 'Test Publisher',
                             secondary_title: 'Secondary Test Title',
                             status: 'Published',
                             volume: '1',
                             issue: '2',
                             edition: '3',
                             page_range: '4-5',
                             url: 'https://url.org',
                             open_access_url: nil,
                             isbn: nil,
                             issn: nil,
                             doi: 'https://doi.org/10.0/1234/4567',
                             abstract: 'Test Abstract',
                             authors_et_al: false,
                             published_on: date
  }
  let(:authorship) { double 'authorship',
                            publication: publication,
                            author_number: 1,
                            orcid_resource_identifier: nil
  }
  let(:contributor1) { double 'contributor', id: 1,
                       first_name: 'Terry',
                       middle_name: "Test",
                       last_name: "McTester"
  }
  let(:contributor2) { double 'contributor', id: 2,
                       first_name: 'Jerry',
                       middle_name: 'Test',
                       last_name: 'McTester'
  }
  subject(:work) { OrcidWork.new(authorship) }

  describe "#to_json" do
    context "when the given authorship has external ids" do
      before { allow(publication).to receive(:doi_url_path).and_return('10.0/1234/5678') }
      before { allow(publication).to receive(:preferred_open_access_url).and_return('https://scholarsphere.org') }
      before { allow(publication).to receive(:contributors).and_return([]) }

      it "returns a JSON representation of an ORCID work that includes external ids" do
        expect(work.to_json).to eq ({
            "title": {
                "title":"Test Title",
                "subtitle":"Secondary Test Title"
            },
            "journal-title":"Test Journal",
            "short-description":"Test Abstract",
            "type":"journal-article",
            "publication-date":{
                "year":date.year,
                "month":date.month,
                "day":date.day
            },
            "external-ids":{
                "external-id":[
                    {
                        "external-id-type":"uri",
                        "external-id-value":"https://scholarsphere.org",
                        "external-id-relationship":"self"
                    },
                    {
                        "external-id-type":"doi",
                        "external-id-value":"10.0/1234/5678",
                        "external-id-relationship":"self"
                    }
                ]
            }
        }.to_json)
      end
    end

    context "when the given authorship's publication has multiple authorships" do
      before { allow(publication).to receive(:doi_url_path).and_return(nil) }
      before { allow(publication).to receive(:preferred_open_access_url).and_return('https://scholarsphere.org') }
      before { allow(publication).to receive(:contributors).and_return([contributor1, contributor2]) }

      it "returns a JSON representation of an ORCID work that includes contributors" do
        expect(work.to_json).to eq ({
            "title": {
                    "title":"Test Title",
                    "subtitle":"Secondary Test Title"
                },
            "journal-title":"Test Journal",
            "short-description":"Test Abstract",
            "type":"journal-article",
            "publication-date": {
                    "year":date.year,
                    "month":date.month,
                    "day":date.day
                },
            "external-ids": {
                    "external-id": [
                        {
                            "external-id-type":"uri",
                            "external-id-value":"https://scholarsphere.org",
                            "external-id-relationship":"self"
                        }
                    ]
            },
            "contributors": {
                    "contributor": [
                        {
                            "credit-name":"Terry Test McTester"
                        },
                        {
                            "credit-name":"Jerry Test McTester"
                        }
                    ]
                }
        }.to_json)
      end
    end
  end

  describe "#orcid_type" do
    it "returns 'work'" do
      expect(work.orcid_type).to eq "work"
    end
  end
end
