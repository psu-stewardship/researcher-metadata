require 'component/component_spec_helper'
require 'component/models/shared_examples_for_an_application_record'

describe 'the publications table', type: :model do
  subject { Publication.new }

  it { is_expected.to have_db_column(:title).of_type(:text).with_options(null: false) }
  it { is_expected.to have_db_column(:publication_type).of_type(:string).with_options(null: false) }
  it { is_expected.to have_db_column(:journal_title).of_type(:text) }
  it { is_expected.to have_db_column(:publisher).of_type(:text) }
  it { is_expected.to have_db_column(:secondary_title).of_type(:text) }
  it { is_expected.to have_db_column(:status).of_type(:string) }
  it { is_expected.to have_db_column(:volume).of_type(:string) }
  it { is_expected.to have_db_column(:issue).of_type(:string) }
  it { is_expected.to have_db_column(:edition).of_type(:string) }
  it { is_expected.to have_db_column(:page_range).of_type(:string) }
  it { is_expected.to have_db_column(:url).of_type(:text) }
  it { is_expected.to have_db_column(:isbn).of_type(:string) }
  it { is_expected.to have_db_column(:issn).of_type(:string) }
  it { is_expected.to have_db_column(:doi).of_type(:string) }
  it { is_expected.to have_db_column(:abstract).of_type(:text) }
  it { is_expected.to have_db_column(:authors_et_al).of_type(:boolean) }
  it { is_expected.to have_db_column(:published_on).of_type(:date) }
  it { is_expected.to have_db_column(:total_scopus_citations).of_type(:integer) }
  it { is_expected.to have_db_column(:open_access_url).of_type(:text) }
  it { is_expected.to have_db_column(:user_submitted_open_access_url).of_type(:text) }
  it { is_expected.to have_db_column(:duplicate_publication_group_id).of_type(:integer) }
  it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_column(:updated_by_user_at).of_type(:datetime) }
  it { is_expected.to have_db_column(:visible).of_type(:boolean).with_options(default: true) }
  it { is_expected.to have_db_column(:open_access_button_last_checked_at).of_type(:datetime) }

  it { is_expected.to have_db_foreign_key(:duplicate_publication_group_id) }

  it { is_expected.to have_db_index(:duplicate_publication_group_id) }
  it { is_expected.to have_db_index(:volume) }
  it { is_expected.to have_db_index(:issue) }
  it { is_expected.to have_db_index(:doi) }
  it { is_expected.to have_db_index(:published_on) }
end


describe Publication, type: :model do
  it_behaves_like "an application record"

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:publication_type) }

    it { is_expected.to validate_inclusion_of(:publication_type).in_array(Publication.publication_types) }

    it 'validates_format_of doi' do
      pub = create :publication
      pub.doi = 'doi:10.1012/abcd123'
      expect(pub).to be_valid
      pub.doi = '10.1000/123456789.ch1'
      expect(pub).to be_valid
      pub.doi = 'https://doi.org/10.1234/words.123.db'
      expect(pub).to be_valid
      pub.doi = 'Junk/doi.org/1234.abc'
      expect(pub).not_to be_valid
    end

    it 'validates_format_of isbn' do
      pub = create :publication
      pub.isbn = 'ISBN 978-0-596-52068-7'
      expect(pub).to be_valid
      pub.isbn = '0-596-52068-9'
      expect(pub).to be_valid
      pub.isbn = '9780596520687'
      expect(pub).to be_valid
      pub.isbn = 'ISBN-13: 978-0-596-52068-7'
      expect(pub).to be_valid
      pub.isbn = 'JUNK/1234-5678'
      expect(pub).not_to be_valid
    end

    it 'validates_format_of issn' do
      pub = create :publication
      pub.issn = '0004-637X'
      expect(pub).to be_valid
      pub.issn = '1471-2164'
      expect(pub).to be_valid
      pub.issn = 'ISSN 1389-0417'
      expect(pub).to be_valid
      pub.issn = 'eISSN 1086-055X'
      expect(pub).to be_valid
      pub.issn = 'https://website.org/work123'
      expect(pub).not_to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:authorships).inverse_of(:publication) }
    it { is_expected.to have_many(:users).through(:authorships) }
    it { is_expected.to have_many(:contributors).dependent(:destroy).inverse_of(:publication) }
    it { is_expected.to have_many(:imports).class_name(:PublicationImport) }
    it { is_expected.to have_many(:taggings).inverse_of(:publication).class_name(:PublicationTagging) }
    it { is_expected.to have_many(:tags).through(:taggings) }
    it { is_expected.to have_many(:organizations).through(:users) }
    it { is_expected.to have_many(:user_organization_memberships).through(:users) }
    it { is_expected.to have_many(:research_funds) }
    it { is_expected.to have_many(:grants).through(:research_funds) }
    it { is_expected.to have_many(:waivers).through(:authorships) }
    it { is_expected.to have_many(:non_duplicate_group_memberships).class_name(:NonDuplicatePublicationGroupMembership).inverse_of(:publication) }
    it { is_expected.to have_many(:non_duplicate_groups).class_name(:NonDuplicatePublicationGroup).through(:non_duplicate_group_memberships)}

    it { is_expected.to belong_to(:duplicate_group).class_name(:DuplicatePublicationGroup).optional.inverse_of(:publications) }
  end

  it { is_expected.to accept_nested_attributes_for(:authorships).allow_destroy(true) }
  it { is_expected.to accept_nested_attributes_for(:contributors).allow_destroy(true) }
  it { is_expected.to accept_nested_attributes_for(:taggings).allow_destroy(true) }

  describe "deleting a publication with authorships" do
    let(:p) { create :publication }
    let!(:a) { create :authorship, publication: p}
    it "also deletes the publication's authorships" do
      p.destroy
      expect { a.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "deleting a publication with contributors" do
    let(:p) { create :publication }
    let!(:c) { create :contributor, publication: p}
    it "also deletes the publication's authorships" do
      p.destroy
      expect { c.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "deleting a publication with taggings" do
    let(:p) { create :publication }
    let!(:pt) { create :publication_tagging, publication: p}
    it "also deletes the publication's taggings" do
      p.destroy
      expect { pt.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "deleting a publication with research funds" do
    let(:p) { create :publication }
    let!(:rf) { create :research_fund, publication: p}
    it "also deletes the publication's research funds" do
      p.destroy
      expect { rf.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe '.publication_types' do
    it "returns the list of valid publication types" do
      expect(Publication.publication_types).to eq ["Academic Journal Article",
                                                   "In-house Journal Article",
                                                   "Professional Journal Article",
                                                   "Trade Journal Article",
                                                   "Journal Article"]
    end
  end

  describe '.visible' do
    let(:visible_pub1) { create :publication, visible: true }
    let(:visible_pub2) { create :publication, visible: true }
    let(:invisible_pub) { create :publication, visible: false }
    it "returns the publications that are marked as visible" do
      expect(Publication.visible).to match_array [visible_pub1, visible_pub2]
    end
  end

  describe '.published_during_membership' do
    let!(:org) { create :organization }
    let!(:other_org) { create :organization }
    let!(:user_1) { create :user }
    let!(:user_2) { create :user }
    let!(:user_3) { create :user }

    let!(:pub_1) { create :publication, visible: true, published_on: Date.new(2000, 1, 1) }
    let!(:pub_2) { create :publication, visible: true, published_on: Date.new(2005, 1, 2) }
    let!(:pub_3) { create :publication, visible: true, published_on: Date.new(1999, 12, 30) }
    let!(:pub_4) { create :publication, visible: true, published_on: Date.new(2001, 1, 1) }
    let!(:pub_5) { create :publication, visible: true, published_on: Date.new(2001, 1, 1) }
    let!(:pub_6) { create :publication, visible: true, published_on: Date.new(2001, 1, 1) }
    let!(:pub_7) { create :publication, visible: true, published_on: Date.new(2019, 1, 1) }
    let!(:pub_8) { create :publication, visible: false, published_on: Date.new(2019, 1, 1) }

    before do
      create :authorship, user: user_1, publication: pub_1 # authored by an org member during their first membership
      create :authorship, user: user_2, publication: pub_1 # also authored by second org member during their membership
      create :authorship, user: user_1, publication: pub_2 # authored by an org member after their membership
      create :authorship, user: user_2, publication: pub_3 # authored by an org member before their membership
      create :authorship, user: user_1, publication: pub_4 # authored by an org member during their first membership
      create :authorship, user: user_2, publication: pub_5 # authored by an org member during their membership
      create :authorship, user: user_3, publication: pub_6 # authored by an org member during their membership
      create :authorship, user: user_1, publication: pub_7 # authored by an org member during their second membership
      create :authorship, user: user_1, publication: pub_8 # authored by an org member during their second membership, but invisible

      create :user_organization_membership,
             user: user_1,
             organization: org,
             started_on: Date.new(1990, 1, 1),
             ended_on: Date.new(2005, 1, 1)
      create :user_organization_membership,
             user: user_1,
             organization: org,
             started_on: Date.new(2015, 1, 1)
      create :user_organization_membership,
             user: user_2,
             organization: org,
             started_on: Date.new(1999, 12, 31)
      create :user_organization_membership,
             user: user_3,
             organization: other_org,
             started_on: Date.new(1980, 1, 1)
    end
    it "returns visible, unique publications by users who were members of an organization when they were published" do
      expect(Publication.published_during_membership).to match_array [pub_1, pub_4, pub_5, pub_6, pub_7]
    end
  end

  describe '.subject_to_open_access_policty' do
    let!(:pub1) { create :publication, published_on: Date.new(2019, 12, 31) }
    let!(:pub2) { create :publication, published_on: Date.new(2020, 1, 1) }
    let!(:pub3) { create :publication, published_on: Date.new(2020, 1, 2) }
    it "returns publications that were published after Penn State's open access policy went into effect" do
      expect(Publication.subject_to_open_access_policy).to match_array [pub2, pub3]
    end
  end

  describe '.find_by_wos_pub' do
    let(:wos_pub) { double 'WoS publication',
                           doi: doi,
                           title: title,
                           publication_date: date }
    let!(:pub1) { create :publication,
                         doi: nil,
                         title: "Another Publication",
                         published_on: Date.new(2000, 1, 1) }
    let!(:pub2) { create :publication,
                         doi: "https://doi.org/10.0/DOI123",
                         title: "Some Text Before The Title Some Text After",
                         published_on: Date.new(2000, 1, 1) }
    let!(:pub3) { create :publication,
                         doi: "https://doi.org/10.0/DOI456",
                         title: "Some Text Before The Title Some Text After",
                         published_on: Date.new(2001, 2, 2) }
    let!(:pub4) { create :publication,
                         doi: "https://doi.org/10.0/DOI111",
                         title: "Another Publication",
                         published_on: Date.new(2001, 2, 2) }
    let!(:pub5) { create :publication,
                         doi: "https://doi.org/10.0/DOI222",
                         title: "Another Publication",
                         published_on: Date.new(2000, 1, 1) }

    context "when given publication data with no DOI" do
      let(:doi) { nil }
      context "when given data with a title that is a case-insensitive, partial match for an existing publication" do
        let(:title) { "THE TITLE" }
        context "when given data with no publication date" do
          let(:date) { nil }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
        context "when given data with a publication year that matches an existing publication" do
          let(:date) { Date.new(2000, 1, 1) }
          it "returns the publication that matches by title and date" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq [pub2]
          end
        end
        context "when given data with a publication year that does not match an existing publication" do
          let(:date) { Date.new(2010, 1, 1) }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
      end
      context "when given data with a title that is not a case-insensitive partial match for an existing publication" do
        let(:title) { "Other Title" }
        context "when given data with no publication date" do
          let(:date) { nil }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
        context "when given data with a publication year that matches an existing publication" do
          let(:date) { Date.new(2000, 1, 1) }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
        context "when given data with a publication year that does not match an existing publication" do
          let(:date) { Date.new(2010, 1, 1) }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
      end
    end
    context "when given publication data with a DOI that matches an existing publication" do
      let(:doi) { "10.0/DOI456" }
      context "when given data with a title that is a case-insensitive, partial match for an existing publication" do
        let(:title) { "THE TITLE" }
        context "when given data with no publication date" do
          let(:date) { nil }
          it "returns the publication with the matching DOI" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq [pub3]
          end
        end
        context "when given data with a publication year that matches an existing publication" do
          let(:date) { Date.new(2000, 1, 1) }
          it "returns the publication with the matching DOI" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq [pub3]
          end
        end
        context "when given data with a publication year that does not match an existing publication" do
          let(:date) { Date.new(2010, 1, 1) }
          it "returns the publication with the matching DOI" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq [pub3]
          end
        end
      end
      context "when given data with a title that is not a case-insensitive partial match for an existing publication" do
        let(:title) { "Other Title" }
        context "when given data with no publication date" do
          let(:date) { nil }
          it "returns the publication with the matching DOI" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq [pub3]
          end
        end
        context "when given data with a publication year that matches an existing publication" do
          let(:date) { Date.new(2000, 1, 1) }
          it "returns the publication with the matching DOI" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq [pub3]
          end
        end
        context "when given data with a publication year that does not match an existing publication" do
          let(:date) { Date.new(2010, 1, 1) }
          it "returns the publication with the matching DOI" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq [pub3]
          end
        end
      end
    end
    context "when given publication data with a DOI that doesn't match an existing publication" do
      let(:doi) { "10.0/DOI789" }
      context "when given data with a title that is a case-insensitive, partial match for an existing publication" do
        let(:title) { "THE TITLE" }
        context "when given data with no publication date" do
          let(:date) { nil }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
        context "when given data with a publication year that matches an existing publication" do
          let(:date) { Date.new(2000, 1, 1) }
          it "returns the publication that matches by title and date" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq [pub2]
          end
        end
        context "when given data with a publication year that does not match an existing publication" do
          let(:date) { Date.new(2010, 1, 1) }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
      end
      context "when given data with a title that is not a case-insensitive partial match for an existing publication" do
        let(:title) { "Other Title" }
        context "when given data with no publication date" do
          let(:date) { nil }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
        context "when given data with a publication year that matches an existing publication" do
          let(:date) { Date.new(2000, 1, 1) }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
        context "when given data with a publication year that does not match an existing publication" do
          let(:date) { Date.new(2010, 1, 1) }
          it "returns an empty array" do
            expect(Publication.find_by_wos_pub(wos_pub)).to eq []
          end
        end
      end
    end
  end

  describe '#confirmed_authorships' do
    let!(:pub) { create :publication }
    let!(:a1) { create :authorship, publication: pub, confirmed: false }
    let!(:a2) { create :authorship, publication: pub, confirmed: true }
    it "returns only the publication's authorships that are confirmed" do
      expect(pub.confirmed_authorships).to eq [a2]
    end
  end

  describe '#contributors' do
    let(:pub) { create :publication }
    let!(:c1) { create :contributor, position: 2, publication: pub }
    let!(:c2) { create :contributor, position: 3, publication: pub }
    let!(:c3) { create :contributor, position: 1, publication: pub }

    it "returns the publication's contributors in order by position" do
      expect(pub.contributors).to eq [c3, c1, c2]
    end
  end

  describe '#ai_import_identifiers' do
    let(:pub) { create :publication }

    before { create :publication_import,
                    source: "Pure",
                    source_identifier: "pure-abc123",
                    publication: pub }

    context "when the publication does not have imports from Activity Insight" do
      it "returns an empty array" do
        expect(pub.ai_import_identifiers).to eq []
      end
    end
    context "when the publication has imports from Activity Insight" do
      before do
        create :publication_import,
               source: "Activity Insight",
               source_identifier: "ai-abc123",
               publication: pub
        create :publication_import,
               source: "Activity Insight",
               source_identifier: "ai-xyz789",
               publication: pub
      end

      it "returns an array of the source identifiers from the publication's Activity Insight imports" do
        expect(pub.ai_import_identifiers).to match_array ["ai-abc123", "ai-xyz789"]
      end
    end
  end

  describe '#pure_import_identifiers' do
    let(:pub) { create :publication }

    before { create :publication_import,
                    source: "Activity Insight",
                    source_identifier: "ai-abc123",
                    publication: pub }

    context "when the publication does not have imports from Pure" do
      it "returns an empty array" do
        expect(pub.pure_import_identifiers).to eq []
      end
    end
    context "when the publication has imports from Pure" do
      before do
        create :publication_import,
               source: "Pure",
               source_identifier: "pure-abc123",
               publication: pub
        create :publication_import,
               source: "Pure",
               source_identifier: "pure-xyz789",
               publication: pub
      end

      it "returns an array of the source identifiers from the publication's Pure imports" do
        expect(pub.pure_import_identifiers).to match_array ["pure-abc123", "pure-xyz789"]
      end
    end
  end

  describe '#mark_as_updated_by_user' do
    let(:pub) { Publication.new }
    before { allow(Time).to receive(:current).and_return Time.new(2018, 8, 23, 10, 7, 0) }

    it "sets the user's updated_by_user_at field to the current time" do
      pub.mark_as_updated_by_user
      expect(pub.updated_by_user_at).to eq Time.new(2018, 8, 23, 10, 7, 0)
    end
  end

  describe '#year' do
    context "when the publication does not have a published_on date" do
      let(:pub) { Publication.new(published_on: nil) }

      it "returns nil" do
        expect(pub.year).to be_nil
      end
    end

    context "when the publication has a published_on date" do
      let(:pub) { Publication.new(published_on: Date.new(2001, 1, 2)) }

      it "returns the year of the publication date" do
        expect(pub.year).to eq 2001
      end
    end
  end

  describe '#published_by' do
    let(:pub) { Publication.new(publisher: publisher, journal_title: jt) }
    context "when the publication has a journal title" do
      let(:jt) { "The Journal" }
      context "when the publication has a publisher" do
        let(:publisher) { "The Publisher" }

        it "returns the journal title" do
          expect(pub.published_by).to eq "The Journal"
        end
      end

      context "when the publication does not have a publisher" do
        let(:publisher) { nil }

        it "returns the journal title" do
          expect(pub.published_by).to eq "The Journal"
        end
      end

      context "when the publication's publisher is blank" do
        let(:publisher) { "" }

        it "returns the journal title" do
          expect(pub.published_by).to eq "The Journal"
        end
      end
    end

    context "when the publication does not have a journal title" do
      let(:jt) { nil }
      context "when the publication has a publisher" do
        let(:publisher) { "The Publisher" }

        it "returns the publisher" do
          expect(pub.published_by).to eq "The Publisher"
        end
      end

      context "when the publication does not have a publisher" do
        let(:publisher) { nil }

        it "returns nil" do
          expect(pub.published_by).to be_nil
        end
      end

      context "when the publication's publisher is blank" do
        let(:publisher) { "" }

        it "returns nil" do
          expect(pub.published_by).to be_nil
        end
      end
    end

    context "when the publication's journal title is blank" do
      let(:jt) { "" }
      context "when the publication has a publisher" do
        let(:publisher) { "The Publisher" }

        it "returns the publisher" do
          expect(pub.published_by).to eq "The Publisher"
        end
      end

      context "when the publication does not have a publisher" do
        let(:publisher) { nil }

        it "returns nil" do
          expect(pub.published_by).to be_nil
        end
      end

      context "when the publication's publisher is blank" do
        let(:publisher) { "" }

        it "returns nil" do
          expect(pub.published_by).to be_nil
        end
      end
    end
  end

  describe '#doi_url_path' do
    let(:pub) { Publication.new(doi: doi) }

    context "when the publication's DOI is nil" do
      let(:doi) { nil }
      it "returns nil" do
        expect(pub.doi_url_path).to eq nil
      end
    end

    context "when the publication's DOI is a full URL" do
      let(:doi) { "https://doi.org/10.1016/S0148-2963(01)00209-0" }
      it "returns only the path part of the URL" do
        expect(pub.doi_url_path).to eq "10.1016/S0148-2963(01)00209-0"
      end
    end
  end

  describe '#preferred_open_access_url' do
    let(:pub) { Publication.new }
    context "when the publication has an open access URL" do
      before { pub.open_access_url = 'A URL' }
      context "when the publication has a user-submitted open access URL" do
        before { pub.user_submitted_open_access_url = 'User URL' }
        it "returns the open access URL" do
          expect(pub.preferred_open_access_url).to eq 'A URL'
        end
      end
      context "when the publication's user-submitted open access URL is blank" do
        before { pub.user_submitted_open_access_url = '' }
        it "returns the open access URL" do
          expect(pub.preferred_open_access_url).to eq 'A URL'
        end
      end
      context "when the publication does not have a user-submitted open access URL" do
        it "returns the open access URL" do
          expect(pub.preferred_open_access_url).to eq 'A URL'
        end
      end
    end

    context "when the publication's open access URL is blank" do
      before { pub.open_access_url = '' }
      context "when the publication has a user-submitted open access URL" do
        before { pub.user_submitted_open_access_url = 'User URL' }
        it "returns the user-submitted open access URL" do
          expect(pub.preferred_open_access_url).to eq 'User URL'
        end
      end
      context "when the publication's user-submitted open access URL is blank" do
        before { pub.user_submitted_open_access_url = '' }
        it "returns nil" do
          expect(pub.preferred_open_access_url).to be_nil
        end
      end
      context "when the publication does not have a user-submitted open access URL" do
        it "returns nil" do
          expect(pub.preferred_open_access_url).to be_nil
        end
      end
    end
    
    context "when the publication does not have an open access URL" do
      context "when the publication has a user-submitted open access URL" do
        before { pub.user_submitted_open_access_url = 'User URL' }
        it "returns the user-submitted open access URL" do
          expect(pub.preferred_open_access_url).to eq 'User URL'
        end
      end
      context "when the publication's user-submitted open access URL is blank" do
        before { pub.user_submitted_open_access_url = '' }
        it "returns nil" do
          expect(pub.preferred_open_access_url).to be_nil
        end
      end
      context "when the publication does not have a user-submitted open access URL" do
        it "returns nil" do
          expect(pub.preferred_open_access_url).to be_nil
        end
      end
    end
  end

  describe "#scholarsphere_upload_pending?" do
    let(:pub) { create :publication }

    before do
      create :authorship, publication: pub, scholarsphere_uploaded_at: upload_time
    end

    context "when the publication has no authorships that have been uploaded to ScholarSphere" do
      let(:upload_time) { nil }
      it "returns false" do
        expect(pub.scholarsphere_upload_pending?).to eq false
      end
    end
    
    context "when the publication has an authorship that has been uploaded to ScholarSphere" do
      let(:upload_time) { Time.current }
      it "returns true" do
        expect(pub.scholarsphere_upload_pending?).to eq true
      end
    end
  end

  describe '#open_access_waived?' do
    let(:pub) { create :publication }
    let!(:auth1) { create :authorship, publication: pub }
    let!(:auth2) { create :authorship, publication: pub }

    context "when none of the publication's authorships have a waiver" do
      it "returns false" do
        expect(pub.open_access_waived?).to eq false
      end
    end

    context "when one of the publication's authorships has a waiver" do
      before { create :internal_publication_waiver, authorship: auth2 }
      it "returns true" do
        expect(pub.open_access_waived?).to eq true
      end
    end
  end

  describe "#no_open_access_information?" do
    let!(:pub) { create :publication }
    let!(:auth1) { create :authorship, publication: pub, scholarsphere_uploaded_at: upload_time }
    let!(:auth2) { create :authorship, publication: pub }
    context "when none of the publication's authorships have a waiver" do
      context "when the publication has no authorships that have been uploaded to ScholarSphere" do
        let(:upload_time) { nil }

        context "when the publication has an open access URL" do
          before { pub.open_access_url = 'A URL' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
    
        context "when the publication's open access URL is blank" do
          before { pub.open_access_url = '' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.no_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.no_open_access_information?).to eq true
            end
          end
        end
        
        context "when the publication does not have an open access URL" do
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.no_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.no_open_access_information?).to eq true
            end
          end
        end
      end
      
      context "when the publication has an authorship that has been uploaded to ScholarSphere" do
        let(:upload_time) { Time.current }

        context "when the publication has an open access URL" do
          before { pub.open_access_url = 'A URL' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
    
        context "when the publication's open access URL is blank" do
          before { pub.open_access_url = '' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
        
        context "when the publication does not have an open access URL" do
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
      end
    end

    context "when one of the publication's authorships has a waiver" do
      before { create :internal_publication_waiver, authorship: auth2 }

      context "when the publication has no authorships that have been uploaded to ScholarSphere" do
        let(:upload_time) { nil }

        context "when the publication has an open access URL" do
          before { pub.open_access_url = 'A URL' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
    
        context "when the publication's open access URL is blank" do
          before { pub.open_access_url = '' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
        
        context "when the publication does not have an open access URL" do
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
      end
      
      context "when the publication has an authorship that has been uploaded to ScholarSphere" do
        let(:upload_time) { Time.current }

        context "when the publication has an open access URL" do
          before { pub.open_access_url = 'A URL' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
    
        context "when the publication's open access URL is blank" do
          before { pub.open_access_url = '' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
        
        context "when the publication does not have an open access URL" do
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.no_open_access_information?).to eq false
            end
          end
        end
      end
    end
  end

  describe "#has_open_access_information?" do
    let!(:pub) { create :publication }
    let!(:auth1) { create :authorship, publication: pub, scholarsphere_uploaded_at: upload_time }
    let!(:auth2) { create :authorship, publication: pub }
    context "when none of the publication's authorships have a waiver" do
      context "when the publication has no authorships that have been uploaded to ScholarSphere" do
        let(:upload_time) { nil }

        context "when the publication has an open access URL" do
          before { pub.open_access_url = 'A URL' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
    
        context "when the publication's open access URL is blank" do
          before { pub.open_access_url = '' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.has_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.has_open_access_information?).to eq false
            end
          end
        end
        
        context "when the publication does not have an open access URL" do
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns false" do
              expect(pub.has_open_access_information?).to eq false
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns false" do
              expect(pub.has_open_access_information?).to eq false
            end
          end
        end
      end
      
      context "when the publication has an authorship that has been uploaded to ScholarSphere" do
        let(:upload_time) { Time.current }

        context "when the publication has an open access URL" do
          before { pub.open_access_url = 'A URL' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
    
        context "when the publication's open access URL is blank" do
          before { pub.open_access_url = '' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
        
        context "when the publication does not have an open access URL" do
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
      end
    end

    context "when one of the publication's authorships has a waiver" do
      before { create :internal_publication_waiver, authorship: auth2 }

      context "when the publication has no authorships that have been uploaded to ScholarSphere" do
        let(:upload_time) { nil }

        context "when the publication has an open access URL" do
          before { pub.open_access_url = 'A URL' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
    
        context "when the publication's open access URL is blank" do
          before { pub.open_access_url = '' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
        
        context "when the publication does not have an open access URL" do
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
      end
      
      context "when the publication has an authorship that has been uploaded to ScholarSphere" do
        let(:upload_time) { Time.current }

        context "when the publication has an open access URL" do
          before { pub.open_access_url = 'A URL' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
    
        context "when the publication's open access URL is blank" do
          before { pub.open_access_url = '' }
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
        
        context "when the publication does not have an open access URL" do
          context "when the publication has a user-submitted open access URL" do
            before { pub.user_submitted_open_access_url = 'User URL' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication's user-submitted open access URL is blank" do
            before { pub.user_submitted_open_access_url = '' }
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
          context "when the publication does not have a user-submitted open access URL" do
            it "returns true" do
              expect(pub.has_open_access_information?).to eq true
            end
          end
        end
      end
    end
  end

  describe '#merge!' do
    let!(:pub1) { create :publication, updated_by_user_at: nil }
    let!(:pub2) { create :publication }
    let!(:pub3) { create :publication }
    let!(:pub4) { create :publication }

    let!(:pub1_import1) { create :publication_import, publication: pub1 }
    let!(:pub2_import1) { create :publication_import, publication: pub2 }
    let!(:pub2_import2) { create :publication_import, publication: pub2 }
    let!(:pub3_import1) { create :publication_import, publication: pub3 }

    it "reassigns all of the imports from the given publications to the publication" do
      pub1.merge!([pub2, pub3, pub4])

      expect(pub1.reload.imports).to match_array [pub1_import1,
                                                  pub2_import1,
                                                  pub2_import2,
                                                  pub3_import1]
    end

    it "deletes the given publications" do
      pub1.merge!([pub2, pub3, pub4])

      expect { pub2.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { pub3.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { pub4.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "updates the modification timestamp on the publication" do
      pub1.merge!([pub2, pub3, pub4])

      expect(pub1.reload.updated_by_user_at).to be_within(1.minute).of(Time.current)
    end


    context "when the given publications include the publication" do
      it "reassigns all of the imports from the given publications to the publication" do
        pub1.merge!([pub1, pub2, pub3, pub4])

        expect(pub1.reload.imports).to match_array [pub1_import1,
                                                    pub2_import1,
                                                    pub2_import2,
                                                    pub3_import1]
      end

      it "deletes the given publications except for the publication" do
        pub1.merge!([pub1, pub2, pub3, pub4])

        expect { pub2.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { pub3.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { pub4.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "updates the modification timestamp on the publication" do
        pub1.merge!([pub1, pub2, pub3, pub4])

        expect(pub1.reload.updated_by_user_at).to be_within(1.minute).of(Time.current)
      end
    end

    context "when an error is raised" do
      before { allow(pub3).to receive(:destroy).and_raise RuntimeError }

      it "does not reassign any imports" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue RuntimeError; end

        expect(pub1.reload.imports).to match_array [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to match_array [pub3_import1]
        expect(pub4.reload.imports).to eq []
      end

      it "does not delete any publications" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue RuntimeError; end

        expect(pub2.reload).to eq pub2
        expect(pub3.reload).to eq pub3
        expect(pub4.reload).to eq pub4
      end

      it "does not update the modification timestamp on the publication" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue RuntimeError; end
        
        expect(pub1.reload.updated_by_user_at).to be_nil
      end
    end

    context "when one of the given publications is in a non-duplicate group" do
      let!(:ndpg) { create :non_duplicate_publication_group, publications: [pub2] }

      it "reassigns all of the imports from the given publications to the publication" do
        pub1.merge!([pub2, pub3, pub4])

        expect(pub1.reload.imports).to match_array [pub1_import1,
                                                    pub2_import1,
                                                    pub2_import2,
                                                    pub3_import1]
      end

      it "deletes the given publications" do
        pub1.merge!([pub2, pub3, pub4])

        expect { pub2.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { pub3.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { pub4.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "updates the modification timestamp on the publication" do
        pub1.merge!([pub2, pub3, pub4])

        expect(pub1.reload.updated_by_user_at).to be_within(1.minute).of(Time.current)
      end

      it "reassigns the publication to the non-duplicate group" do
        pub1.merge!([pub2, pub3, pub4])

        expect(ndpg.reload.publications).to eq [pub1]
      end
    end

    context "when two of the given publications are in two different non-duplicate groups" do
      let!(:ndpg1) { create :non_duplicate_publication_group, publications: [pub2] }
      let!(:ndpg2) { create :non_duplicate_publication_group, publications: [pub4] }

      it "reassigns all of the imports from the given publications to the publication" do
        pub1.merge!([pub2, pub3, pub4])

        expect(pub1.reload.imports).to match_array [pub1_import1,
                                                    pub2_import1,
                                                    pub2_import2,
                                                    pub3_import1]
      end

      it "deletes the given publications" do
        pub1.merge!([pub2, pub3, pub4])

        expect { pub2.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { pub3.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { pub4.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "updates the modification timestamp on the publication" do
        pub1.merge!([pub2, pub3, pub4])

        expect(pub1.reload.updated_by_user_at).to be_within(1.minute).of(Time.current)
      end

      it "reassigns the publications to the non-duplicate groups" do
        pub1.merge!([pub2, pub3, pub4])

        expect(ndpg1.reload.publications).to eq [pub1]
        expect(ndpg2.reload.publications).to eq [pub1]
      end
    end

    context "when two of the given publications are in the same non-duplicate group" do
      let!(:ndpg) { create :non_duplicate_publication_group, publications: [pub2, pub4] }

      it "raises an error" do
        expect { pub1.merge!([pub2, pub3, pub4]) }.to raise_error Publication::NonDuplicateMerge
      end

      it "does not reassign any imports" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub1.reload.imports).to match_array [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to match_array [pub3_import1]
        expect(pub4.reload.imports).to eq []
      end

      it "does not delete any publications" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub2.reload).to eq pub2
        expect(pub3.reload).to eq pub3
        expect(pub4.reload).to eq pub4
      end

      it "does not update the modification timestamp on the publication" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub1.reload.updated_by_user_at).to be_nil
      end

      it "does not update any non-duplicate groups" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(ndpg.reload.publications).to match_array [pub2, pub4]
      end
    end

    context "when two of the given publications are both in two different non-duplicate group" do
      let!(:ndpg1) { create :non_duplicate_publication_group, publications: [pub2, pub4] }
      let!(:ndpg2) { create :non_duplicate_publication_group, publications: [pub2, pub4] }

      it "raises an error" do
        expect { pub1.merge!([pub2, pub3, pub4]) }.to raise_error Publication::NonDuplicateMerge
      end

      it "does not reassign any imports" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub1.reload.imports).to match_array [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to match_array [pub3_import1]
        expect(pub4.reload.imports).to eq []
      end

      it "does not delete any publications" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub2.reload).to eq pub2
        expect(pub3.reload).to eq pub3
        expect(pub4.reload).to eq pub4
      end

      it "does not update the modification timestamp on the publication" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub1.reload.updated_by_user_at).to be_nil
      end

      it "does not update any non-duplicate groups" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(ndpg1.reload.publications).to match_array [pub2, pub4]
        expect(ndpg2.reload.publications).to match_array [pub2, pub4]
      end
    end

    context "when one of the given publications is in the same non-duplicate group as the publication" do
      let!(:ndpg) { create :non_duplicate_publication_group, publications: [pub1, pub3] }

      it "raises an error" do
        expect { pub1.merge!([pub2, pub3, pub4]) }.to raise_error Publication::NonDuplicateMerge
      end

      it "does not reassign any imports" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub1.reload.imports).to match_array [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to match_array [pub3_import1]
        expect(pub4.reload.imports).to eq []
      end

      it "does not delete any publications" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub2.reload).to eq pub2
        expect(pub3.reload).to eq pub3
        expect(pub4.reload).to eq pub4
      end

      it "does not update the modification timestamp on the publication" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub1.reload.updated_by_user_at).to be_nil
      end

      it "does not update any non-duplicate groups" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(ndpg.reload.publications).to match_array [pub1, pub3]
      end
    end

    context "when all of the publications are in the same non-duplicate group" do
      let!(:ndpg) { create :non_duplicate_publication_group, publications: [pub1, pub2, pub3, pub4] }

      it "raises an error" do
        expect { pub1.merge!([pub2, pub3, pub4]) }.to raise_error Publication::NonDuplicateMerge
      end

      it "does not reassign any imports" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub1.reload.imports).to match_array [pub1_import1]
        expect(pub2.reload.imports).to match_array [pub2_import1, pub2_import2]
        expect(pub3.reload.imports).to match_array [pub3_import1]
        expect(pub4.reload.imports).to eq []
      end

      it "does not delete any publications" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub2.reload).to eq pub2
        expect(pub3.reload).to eq pub3
        expect(pub4.reload).to eq pub4
      end

      it "does not update the modification timestamp on the publication" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(pub1.reload.updated_by_user_at).to be_nil
      end

      it "does not update any non-duplicate groups" do
        begin
          pub1.merge!([pub2, pub3, pub4])
        rescue Publication::NonDuplicateMerge; end

        expect(ndpg.reload.publications).to match_array [pub1, pub2, pub3, pub4]
      end
    end
  end
end
