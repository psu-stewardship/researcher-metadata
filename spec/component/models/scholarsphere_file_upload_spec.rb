require 'component/component_spec_helper'
require 'component/models/shared_examples_for_an_application_record'

describe 'the scholarsphere_file_uploads table', type: :model do
  subject { ScholarsphereFileUpload.new }

  it { is_expected.to have_db_column(:id).of_type(:integer).with_options(null: false) }
  it { is_expected.to have_db_column(:authorship_id).of_type(:integer) }
  it { is_expected.to have_db_column(:file).of_type(:string) }
  it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }

  it { is_expected.to have_db_index(:authorship_id) }

  it { is_expected.to have_db_foreign_key(:authorship_id) }
end

describe ScholarsphereFileUpload, type: :model do
  subject(:upload) { ScholarsphereFileUpload.new }

  it_behaves_like "an application record"

  it { is_expected.to belong_to(:authorship) }

  it { is_expected.to validate_presence_of(:file) }

  describe "#file" do
    it "mounts a ScholarsphereFileUploader" do
      expect(upload.file).to be_a(ScholarsphereFileUploader)
    end
  end

  describe '#destroy' do
    let!(:upload) { create :scholarsphere_file_upload }
    it 'removes the file from the filesystem' do
      expect(File.exist?(upload.file.path)).to eq true
      upload.destroy
      expect(File.exist?(upload.file.path)).to eq false
    end
  end
end
