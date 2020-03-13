require 'component/component_spec_helper'

describe PurePublicationTagImporter do
  let(:importer) { PurePublicationTagImporter.new(filename: filename) }

  describe '#call' do
    context "when given a well-formed .json file of publicaiton fingerprint data from Pure" do
      let(:filename) { Rails.root.join('spec', 'fixtures', 'pure_publication_fingerprints.json') }

      context "when no publications in the database match the publication data being imported" do
        it "runs" do
          expect { importer.call }.not_to raise_error
        end

        it "does not create any new tags" do
          expect { importer.call }.not_to change { Tag.count }
        end

        it "does not create any new publication taggingss" do
          expect { importer.call }.not_to change { PublicationTagging.count }
        end
      end

      context "when publications in the database match the publication data being imported" do
        let!(:imp1) { create :publication_import,
                             source: "Pure",
                             source_identifier: "e1b21d75-4579-4efc-9fcc-dcd9827ee51a",
                             publication: pub1 }
        let!(:imp2) { create :publication_import,
                             source: "Pure",
                             source_identifier: "890420eb-eff9-4cbc-8e1b-20f68460f4eb",
                             publication: pub2 }

        let!(:pub1) { create :publication }
        let!(:pub2) { create :publication }

              
        let(:found_tag1) { Tag.find_by(name: 'Psychotherapy') }
        let(:found_tag2) { Tag.find_by(name: 'Metal Spinning') }
        let(:found_tag3) { Tag.find_by(name: 'Simulation') }

        it "runs" do
          expect { importer.call }.not_to raise_error
        end

        context "when no matching tags already exist" do
          it "creates a new tag for each new term in the given fingerprint data" do
            expect { importer.call }.to change { Tag.count }.by 3
          end

          it "titlizes the names of the saved tags" do
            importer.call

            expect(found_tag1).not_to be_nil
            expect(found_tag2).not_to be_nil
            expect(found_tag3).not_to be_nil
          end

          it "associates the tags with the correct publications" do
            expect { importer.call }.to change { PublicationTagging.count }.by 3

            expect(pub1.tags).to eq [found_tag1]
            expect(pub2.tags).to match_array [found_tag2, found_tag3]
          end

          it "saves the correct ranks on the taggings" do
            importer.call

            tagging1 = PublicationTagging.find_by(tag: found_tag1, publication: pub1)
            tagging2 = PublicationTagging.find_by(tag: found_tag2, publication: pub2)
            tagging3 = PublicationTagging.find_by(tag: found_tag3, publication: pub2)

            expect(tagging1.rank).to eq 2.0
            expect(tagging2.rank).to eq 0.5
            expect(tagging3.rank).to eq 0.5
          end
        end

        context "when a matching tag already exists" do
          let!(:tag) { create :tag, name: 'Simulation' }
          it "only creates new tags for new terms in the given fingerprint data" do
            expect { importer.call }.to change { Tag.count }.by 2
          end

          it "titlizes the names of the saved tags" do
            importer.call

            expect(found_tag1).not_to be_nil
            expect(found_tag2).not_to be_nil
            expect(found_tag3).not_to be_nil
          end

          it "associates the tags with the correct publications" do
            expect { importer.call }.to change { PublicationTagging.count }.by 3

            expect(pub1.tags).to eq [found_tag1]
            expect(pub2.tags).to match_array [found_tag2, found_tag3]
          end

          it "saves the correct ranks on the taggings" do
            importer.call

            tagging1 = PublicationTagging.find_by(tag: found_tag1, publication: pub1)
            tagging2 = PublicationTagging.find_by(tag: found_tag2, publication: pub2)
            tagging3 = PublicationTagging.find_by(tag: found_tag3, publication: pub2)

            expect(tagging1.rank).to eq 2.0
            expect(tagging2.rank).to eq 0.5
            expect(tagging3.rank).to eq 0.5
          end

          context "when a matching tagging already exists" do
            before { create :publication_tagging, tag: tag, publication: pub2, rank: 3.0 }

            it "does not duplicate the existing tagging" do
              expect { importer.call }.to change { PublicationTagging.count }.by 2
            end

            it "saves the correct ranks on the taggings and doesn't update the existing tagging's rank" do
              importer.call

              tagging1 = PublicationTagging.find_by(tag: found_tag1, publication: pub1)
              tagging2 = PublicationTagging.find_by(tag: found_tag2, publication: pub2)
              tagging3 = PublicationTagging.find_by(tag: found_tag3, publication: pub2)

              expect(tagging1.rank).to eq 2.0
              expect(tagging2.rank).to eq 0.5
              expect(tagging3.rank).to eq 3.0
            end
          end
        end
      end
    end
  end
end