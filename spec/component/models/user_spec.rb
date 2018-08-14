require 'component/component_spec_helper'

describe 'the users table', type: :model do
  subject(:user) { User.new }
  it { is_expected.to have_db_column(:activity_insight_identifier).of_type(:string) }
  it { is_expected.to have_db_column(:first_name).of_type(:string) }
  it { is_expected.to have_db_column(:middle_name).of_type(:string) }
  it { is_expected.to have_db_column(:last_name).of_type(:string) }
  it { is_expected.to have_db_column(:title).of_type(:string) }
  it { is_expected.to have_db_column(:webaccess_id).of_type(:string).with_options(null: false) }
  it { is_expected.to have_db_column(:penn_state_identifier).of_type(:string) }
  it { is_expected.to have_db_column(:is_admin).of_type(:boolean).with_options(default: false) }
  it { is_expected.to have_db_column(:pure_uuid).of_type(:string) }
  it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_column(:updated_by_user_at).of_type(:datetime) }

  it { is_expected.to have_db_index(:activity_insight_identifier).unique(true) }
  it { is_expected.to have_db_index(:pure_uuid).unique(true) }
  it { is_expected.to have_db_index(:webaccess_id).unique(true) }
  it { is_expected.to have_db_index(:penn_state_identifier).unique(true) }
end

describe User, type: :model do
  subject(:user) { User.new }

  describe 'associations' do
    it { is_expected.to have_many(:authorships) }
    it { is_expected.to have_many(:publications).through(:authorships) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:webaccess_id) }

    context "given an otherwise valid record" do
      subject { User.new(webaccess_id: 'abc123') }
      it { is_expected.to validate_uniqueness_of(:webaccess_id).case_insensitive }
      it { is_expected.to validate_uniqueness_of(:activity_insight_identifier).allow_nil }
      it { is_expected.to validate_uniqueness_of(:pure_uuid).allow_nil }
      it { is_expected.to validate_uniqueness_of(:penn_state_identifier).allow_nil }
    end
  end

  describe "saving a value for webaccess_id" do
    let(:u) { create :user, webaccess_id: wa_id }
    context "when the value contains uppercase letters" do
      let(:wa_id) { 'ABC123' }
      it "converts letters to lowercase before saving" do
        expect(u.webaccess_id).to eq 'abc123'
      end
    end
    context "when the value does not contain uppercase letters" do
      let(:wa_id) { 'xyz789' }
      it "saves the string without modifying it" do
        expect(u.webaccess_id).to eq 'xyz789'
      end
    end
  end

  describe "saving a value for penn_state_identifier" do
    let(:u) { create :user, penn_state_identifier: psu_id }
    context "when given nil" do
      let(:psu_id) { nil }
      it "saves the value as nil" do
        expect(u.penn_state_identifier).to eq nil
      end
    end
    context "when given an empty string" do
      let(:psu_id) { '' }
      it "saves the value as nil" do
        expect(u.penn_state_identifier).to eq nil
      end
    end
    context "when given a blank string" do
      let(:psu_id) { ' ' }
      it "saves the value as nil" do
        expect(u.penn_state_identifier).to eq nil
      end
    end
    context "when given a non-blank string" do
      let(:psu_id) { 'a' }
      it "saves the value of the string" do
        expect(u.penn_state_identifier).to eq 'a'
      end
    end
  end

  describe "saving a value for pure_uuid" do
    let(:u) { create :user, pure_uuid: pure_id }
    context "when given nil" do
      let(:pure_id) { nil }
      it "saves the value as nil" do
        expect(u.pure_uuid).to eq nil
      end
    end
    context "when given an empty string" do
      let(:pure_id) { '' }
      it "saves the value as nil" do
        expect(u.pure_uuid).to eq nil
      end
    end
    context "when given a blank string" do
      let(:pure_id) { ' ' }
      it "saves the value as nil" do
        expect(u.pure_uuid).to eq nil
      end
    end
    context "when given a non-blank string" do
      let(:pure_id) { 'a' }
      it "saves the value of the string" do
        expect(u.pure_uuid).to eq 'a'
      end
    end
  end

  describe "saving a value for activity_insight_identifier" do
    let(:u) { create :user, activity_insight_identifier: ai_id }
    context "when given nil" do
      let(:ai_id) { nil }
      it "saves the value as nil" do
        expect(u.activity_insight_identifier).to eq nil
      end
    end
    context "when given an empty string" do
      let(:ai_id) { '' }
      it "saves the value as nil" do
        expect(u.activity_insight_identifier).to eq nil
      end
    end
    context "when given a blank string" do
      let(:ai_id) { ' ' }
      it "saves the value as nil" do
        expect(u.activity_insight_identifier).to eq nil
      end
    end
    context "when given a non-blank string" do
      let(:ai_id) { 'a' }
      it "saves the value of the string" do
        expect(u.activity_insight_identifier).to eq 'a'
      end
    end
  end

  describe "deleting a user with authorships" do
    let(:u) { create :user }
    let!(:a) { create :authorship, user: u}
    it "also deletes the user's authorships" do
      u.destroy
      expect { a.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe '#admin?' do
    context "when the user's is_admin value is true" do
      before { user.is_admin = true }
      it "returns true" do
        expect(user.admin?).to eq true
      end
    end

    context "when the user's is_admin value is false" do
      before { user.is_admin = false }
      it "returns false" do
        expect(user.admin?).to eq false
      end
    end
  end

  describe '#name' do
    before { user.first_name = 'Buck'; user.last_name = 'Murphy' }
    context "when middle_name is not blank" do
      before { user.middle_name = 'X' }
      it "returns the first, middle, and last name" do
        expect(user.name).to eq 'Buck X Murphy'
      end
    end
    context "when middle_name is blank" do
      before { user.middle_name = '' }
      it "returns the first and last name" do
        expect(user.name).to eq 'Buck Murphy'
      end
    end
  end
end
