require 'component/component_spec_helper'
  
describe 'the performance table', type: :model do
  subject { Performance.new }

  it { is_expected.to have_db_column(:id).of_type(:integer).with_options(null: false) }
  it { is_expected.to have_db_column(:title).of_type(:text).with_options(null: false) }
  it { is_expected.to have_db_column(:performance_type).of_type(:string) }
  it { is_expected.to have_db_column(:type_other).of_type(:text) }
  it { is_expected.to have_db_column(:sponsor).of_type(:text) }
  it { is_expected.to have_db_column(:description).of_type(:text) }
  it { is_expected.to have_db_column(:group_name).of_type(:text) }
  it { is_expected.to have_db_column(:location).of_type(:text) }
  it { is_expected.to have_db_column(:delivery_type).of_type(:string) }
  it { is_expected.to have_db_column(:scope).of_type(:string) }
  it { is_expected.to have_db_column(:start_on).of_type(:date) }
  it { is_expected.to have_db_column(:end_on).of_type(:date) }
  it { is_expected.to have_db_column(:updated_by_user_at).of_type(:datetime) }
  it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_column(:visible).of_type(:boolean).with_options(default: false) }
end

describe Performance, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:users).through(:user_performances) }
    it { is_expected.to have_many(:user_performances).inverse_of(:performance) }
    it { is_expected.to have_many(:imports).class_name(:PerformanceImport) }
  end

  describe "deleting a performance with user_performances" do
    let(:p) { create :performance }
    let!(:up) { create :user_performance, performance: p}
    it "also deletes the performance's user_performances" do
      p.destroy
      expect { up.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "deleting a performance with performance_imports" do
    let(:p) { create :performance }
    let!(:pi) { create :performance_import, performance: p}
    it "also deletes the performance's performance_imports" do
      p.destroy
      expect { pi.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
