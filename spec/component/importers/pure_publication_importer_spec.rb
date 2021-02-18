require 'component/component_spec_helper'

describe PurePublicationImporter do
  let(:importer) { PurePublicationImporter.new(dirname: dirname) }
  let!(:pub1auth1) { create :user, pure_uuid: '5ec8ce05-0912-4d68-8633-c5618a3cf15d'}
  let!(:pub2auth4) { create :user, pure_uuid: 'dc40be59-e778-404c-aaed-eddb9a992cb8'} # second publication is not an article
  let!(:pub3auth2) { create :user, pure_uuid: '82195bc6-c5cd-479e-b6f8-545f0f0555ba'}

  let(:found_pub1) { PublicationImport.find_by(source: 'Pure', source_identifier: 'e1b21d75-4579-4efc-9fcc-dcd9827ee51a') }
  let(:found_pub2) { PublicationImport.find_by(source: 'Pure', source_identifier: 'bfc570c3-10d8-451e-9145-c370d6f01c64') }

  let!(:journal) { create :journal,
                          pure_uuid: '6bd3ad47-c2bf-44cb-9d79-85d9fe14550f' }
  describe '#call' do
    let!(:duplicate_pub1) { create :publication, title: "Third Test Publication With a Really Unique Title", visible: true }
    let!(:duplicate_pub2) { create :publication, title: "Third Test Publication With a Really Unique Title", visible: true }
    
    context "when given a directory containing well-formed .json files of valid publication data from Pure" do
      let(:dirname) { Rails.root.join('spec', 'fixtures', 'pure_publications') }

      context "when no publication import records exist in the database" do
        it "creates a new publication import record for each object in the .json files that is an article" do
          expect { importer.call }.to change { PublicationImport.count }.by 2
        end

        it "creates a new publication record for each object in the .json files that is an article" do
          expect { importer.call }.to change { Publication.count }.by 2 # There are 3 publications, but one is a letter
        end

        it "creates a new contributor name record for each author on each article" do
          expect { importer.call }.to change { ContributorName.count }.by 7
        end

        it "creates a new authorship record for each author who is a Penn State user on each article" do
          expect { importer.call }.to change { Authorship.count }.by 2 # There are 2 articles, each with one PSU author
        end

        it "saves the correct data for each publication import" do
          importer.call

          expect(found_pub1.source_updated_at).to eq Time.parse('2018-03-14T20:47:06.357+0000')
          expect(found_pub2.source_updated_at).to eq Time.parse('2018-05-01T01:10:03.735+0000')
        end

        it "saves the correct data for each publication" do
          importer.call

          p1 = found_pub1.publication
          p2 = found_pub2.publication

          expect(p1.title).to eq 'The First Publication'
          expect(p2.title).to eq 'Third Test Publication With a Really Unique Title'

          expect(p1.secondary_title).to eq 'From Pure'
          expect(p2.secondary_title).to eq nil

          expect(p1.publication_type).to eq 'Academic Journal Article'
          expect(p2.publication_type).to eq 'Academic Journal Article'

          expect(p1.page_range).to eq '91-95'
          expect(p2.page_range).to eq '665-680'

          expect(p1.volume).to eq '6'
          expect(p2.volume).to eq '30'

          expect(p1.issue).to eq '2'
          expect(p2.issue).to eq '3'

          expect(p1.journal).to eq nil
          expect(p2.journal).to eq journal

          expect(p1.issn).to eq '0962-1849'
          expect(p2.issn).to eq '0272-4634'

          expect(p1.status).to eq 'Published'
          expect(p2.status).to eq 'Published'

          expect(p1.published_on).to eq Date.new(1997, 1, 1)
          expect(p2.published_on).to eq Date.new(2010, 5, 1)

          expect(p1.total_scopus_citations).to eq 2
          expect(p2.total_scopus_citations).to eq 32

          expect(p1.abstract).to be_nil
          expect(p2.abstract).to eq '<p>This is the third abstract.</p>'

          expect(p1.visible).to eq true
          expect(p2.visible).to eq true

          expect(p1.doi).to eq 'https://doi.org/10.1016/S0962-1849(05)80014-9'
          expect(p2.doi).to be nil
        end

        it "saves the correct data for each contributor name" do
          importer.call

          p1 = found_pub1.publication
          p2 = found_pub2.publication

          expect(p1.contributor_names.count).to eq 2
          expect(p2.contributor_names.count).to eq 5

          expect(p1.contributor_names.find_by(first_name: 'Firstpub R.',
                                              middle_name: nil,
                                              last_name: 'Firstauthor',
                                              position: 1)).not_to be_nil
          expect(p1.contributor_names.find_by(first_name: 'Firstpub',
                                              middle_name: nil,
                                              last_name: 'Secondauthor',
                                              position: 2)).not_to be_nil

          expect(p2.contributor_names.find_by(first_name: 'Thirdpub A.',
                                              middle_name: nil,
                                              last_name: 'Firstauthor',
                                              position: 1)).not_to be_nil
          expect(p2.contributor_names.find_by(first_name: 'Thirdpub',
                                              middle_name: nil,
                                              last_name: 'Secondauthor',
                                              position: 2)).not_to be_nil
          expect(p2.contributor_names.find_by(first_name: 'Thirdpub',
                                              middle_name: nil,
                                              last_name: 'Thirdauthor',
                                              position: 3)).not_to be_nil
          expect(p2.contributor_names.find_by(first_name: 'Thirdpub',
                                              middle_name: nil,
                                              last_name: 'Fourthauthor',
                                              position: 4)).not_to be_nil
          expect(p2.contributor_names.find_by(first_name: 'Thirdpub',
                                              middle_name: nil,
                                              last_name: 'Fifthauthor',
                                              position: 5)).not_to be_nil
        end

        it "saves the correct data for each authorship" do
          importer.call

          expect(Authorship.find_by(publication: found_pub1.publication,
                                    user: pub1auth1,
                                    author_number: 1)).not_to be_nil

          expect(Authorship.find_by(publication: found_pub2.publication,
                                    user: pub3auth2,
                                    author_number: 2)).not_to be_nil
        end

        it "groups possible duplicates of new publication records" do
          expect { importer.call }.to change { DuplicatePublicationGroup.count }.by 1

          p2 = found_pub2.publication
          group = p2.duplicate_group
          
          expect(group.publications).to match_array [p2, duplicate_pub1, duplicate_pub2]
        end

        it "hides existing publications that might be duplicates" do
          importer.call

          p2 = found_pub2.publication

          expect(p2.visible).to eq true
          expect(duplicate_pub1.reload.visible).to eq false
          expect(duplicate_pub2.reload.visible).to eq false
        end
      end

      context "when a publication record and a publication import record already exist for one of the publications in the .json files" do
        let!(:existing_import) { create :publication_import,
                                        source: 'Pure',
                                        source_identifier: 'e1b21d75-4579-4efc-9fcc-dcd9827ee51a',
                                        source_updated_at: Time.new(1999, 12, 31, 23, 59, 59),
                                        publication: existing_pub }
        let(:existing_pub) { create :publication,
                                    updated_by_user_at: updated_ts,
                                    title: 'Existing Title',
                                    secondary_title: 'Existing Subtitle',
                                    publication_type: 'Journal Article',
                                    journal: existing_journal,
                                    page_range: 'existing range',
                                    volume: 'existing volume',
                                    issue: 'existing issue',
                                    issn: 'existing issn',
                                    status: 'existing status',
                                    published_on: Date.new(2018, 8, 22),
                                    total_scopus_citations: 1,
                                    abstract: 'existing abstract',
                                    visible: false,
                                    doi: doi }
        let(:doi) { "existing DOI" }
        let(:existing_journal) { create :journal }
        
        context "when the existing publication record has not been manually updated" do
          let(:updated_ts) { nil }

          it "creates a new publication import record for each new object in the .json files that is an article" do
            expect { importer.call }.to change { PublicationImport.count }.by 1
          end
  
          it "creates a new publication record for each new object in the .json files that is an article" do
            expect { importer.call }.to change { Publication.count }.by 1
          end
  
          context "when no contributor name records exist" do
            it "creates a new contributor name record for each author on each article" do
              expect { importer.call }.to change { ContributorName.count }.by 7
              expect(existing_pub.contributor_names.count).to eq 2

              expect(existing_pub.contributor_names.find_by(first_name: 'Firstpub R.',
                                                            middle_name: nil,
                                                            last_name: 'Firstauthor',
                                                            position: 1)).not_to be_nil
              expect(existing_pub.contributor_names.find_by(first_name: 'Firstpub',
                                                            middle_name: nil,
                                                            last_name: 'Secondauthor',
                                                            position: 2)).not_to be_nil
            end
          end
  
          context "when contributor name records already exist for the existing publication" do
            let!(:existing_name) { create :contributor_name,
                                          first_name: 'An',
                                          middle_name: 'Existing',
                                          last_name: 'Contributor',
                                          position: 3,
                                          publication: existing_pub }

            it "replaces the existing contributor name records with new records from the import data" do
              expect { importer.call }.to change { ContributorName.count }.by 6
              expect(existing_pub.contributor_names.count).to eq 2

              expect(existing_pub.contributor_names.find_by(first_name: 'Firstpub R.',
                                                            middle_name: nil,
                                                            last_name: 'Firstauthor',
                                                            position: 1)).not_to be_nil
              expect(existing_pub.contributor_names.find_by(first_name: 'Firstpub',
                                                            middle_name: nil,
                                                            last_name: 'Secondauthor',
                                                            position: 2)).not_to be_nil
            end
          end
  
          context "when no authorship records exist" do
            it "creates a new authorship record for each author who is a Penn State user on each article " do
              expect { importer.call }.to change { Authorship.count }.by 2

              expect(Authorship.find_by(publication: found_pub1.publication,
                                        user: pub1auth1,
                                        author_number: 1,
                                        confirmed: true)).not_to be_nil

              expect(Authorship.find_by(publication: found_pub2.publication,
                                        user: pub3auth2,
                                        author_number: 2,
                                        confirmed: true)).not_to be_nil
            end
          end
  
          context "when an authorship record already exists for the existing publication and user" do
            let!(:existing_auth) { create :authorship,
                                   user: pub1auth1,
                                   publication: existing_pub,
                                   author_number: 6 }

            it "does not create a new authorship record" do
              expect { importer.call }.to change { Authorship.count }.by 1
            end
            it "updates the existing authorship record with the new authorship data" do
              importer.call
              expect(existing_auth.reload.author_number).to eq 1
            end
          end

          it "updates the existing publication import with the new data" do
            importer.call
            expect(existing_import.reload.source_updated_at).to eq Time.parse('2018-03-14T20:47:06.357+0000')
          end

          it "updates the existing publication with the new data" do
            importer.call

            updated_pub = existing_pub.reload

            expect(updated_pub.title).to eq 'The First Publication'
            expect(updated_pub.secondary_title).to eq 'From Pure'
            expect(updated_pub.publication_type).to eq 'Academic Journal Article'
            expect(updated_pub.page_range).to eq '91-95'
            expect(updated_pub.volume).to eq '6'
            expect(updated_pub.issue).to eq '2'
            expect(updated_pub.journal).to be_nil
            expect(updated_pub.issn).to eq '0962-1849'
            expect(updated_pub.status).to eq 'Published'
            expect(updated_pub.published_on).to eq Date.new(1997, 1, 1)
            expect(updated_pub.total_scopus_citations).to eq 2
            expect(updated_pub.abstract).to be_nil
            expect(updated_pub.visible).to eq true
            expect(updated_pub.doi).to eq 'https://doi.org/10.1016/S0962-1849(05)80014-9'
          end
          
          it "creates new publications with the correct data" do
            importer.call

            new_pub = found_pub2.publication

            expect(new_pub.title).to eq 'Third Test Publication With a Really Unique Title'
            expect(new_pub.secondary_title).to eq nil
            expect(new_pub.publication_type).to eq 'Academic Journal Article'
            expect(new_pub.page_range).to eq '665-680'
            expect(new_pub.volume).to eq '30'
            expect(new_pub.issue).to eq '3'
            expect(new_pub.journal).to eq journal
            expect(new_pub.issn).to eq '0272-4634'
            expect(new_pub.status).to eq 'Published'
            expect(new_pub.published_on).to eq Date.new(2010, 5, 1)
            expect(new_pub.total_scopus_citations).to eq 32
            expect(new_pub.abstract).to eq '<p>This is the third abstract.</p>'
            expect(new_pub.visible).to eq true
            expect(new_pub.doi).to be_nil
          end

          it "groups possible duplicates of new publication records" do
            expect { importer.call }.to change { DuplicatePublicationGroup.count }.by 1

            p2 = found_pub2.publication
            group = p2.duplicate_group
            
            expect(group.publications).to match_array [p2, duplicate_pub1, duplicate_pub2]
          end

          it "hides existing publications that might be duplicates" do
            importer.call

            p2 = found_pub2.publication

            expect(p2.visible).to eq true
            expect(duplicate_pub1.reload.visible).to eq false
            expect(duplicate_pub2.reload.visible).to eq false
          end
        end
        
        context "when the existing publication record has been manually updated" do
          let(:updated_ts) { Time.now }
          let!(:new_journal) { create :journal,
                                      pure_uuid: 'e72f86d9-88a4-4dea-9b0a-8cb1cccb82ad' }

          it "creates a new publication import record for each new object in the .json files that is an article" do
            expect { importer.call }.to change { PublicationImport.count }.by 1
          end

          it "creates a new publication record for each new object in the .json files that is an article" do
            expect { importer.call }.to change { Publication.count }.by 1
          end

          context "when no contributor name records exist" do
            it "creates a new contributor name record for each author on each new article only" do
              expect { importer.call }.to change { ContributorName.count }.by 5
              expect(existing_pub.contributor_names.count).to eq 0
            end
          end

          context "when contributor name records already exist for the existing publication" do
            let!(:existing_name) { create :contributor_name,
                                          first_name: 'An',
                                          middle_name: 'Existing',
                                          last_name: 'Contributor',
                                          position: 3,
                                          publication: existing_pub }

            it "does not modify existing contributor name records on the existing publication" do
              expect { importer.call }.to change { ContributorName.count }.by 5
              expect(existing_pub.contributor_names.count).to eq 1

              expect(existing_pub.contributor_names.find_by(first_name: 'An',
                                                            middle_name: 'Existing',
                                                            last_name: 'Contributor',
                                                            position: 3)).not_to be_nil
            end
          end

          context "when no authorship records exist" do
            it "creates a new authorship record for each author who is a Penn State user on each new article only" do
              expect { importer.call }.to change { Authorship.count }.by 1

              expect(Authorship.find_by(publication: found_pub1.publication,
                                        user: pub1auth1,
                                        author_number: 1)).to be_nil

              expect(Authorship.find_by(publication: found_pub2.publication,
                                        user: pub3auth2,
                                        author_number: 2,
                                        confirmed: true)).not_to be_nil
            end
          end

          context "when an authorship record already exists for the existing publication and user" do
            let!(:existing_auth) { create :authorship,
                                          user: pub1auth1,
                                          publication: existing_pub,
                                          author_number: 6 }

            it "does not create a new authorship record" do
              expect { importer.call }.to change { Authorship.count }.by 1
            end
            it "does not update the existing authorship record with new authorship data" do
              importer.call
              expect(existing_auth.reload.author_number).to eq 6
            end
          end

          it "updates the existing publication import with the new data" do
            importer.call
            expect(existing_import.reload.source_updated_at).to eq Time.parse('2018-03-14T20:47:06.357+0000')
          end

          context "when the existing publication already has a DOI" do
            it "updates only the Scopus citation count on the existing publication" do
              importer.call

              existing_pub_reloaded = existing_pub.reload

              expect(existing_pub_reloaded.title).to eq 'Existing Title'
              expect(existing_pub_reloaded.secondary_title).to eq 'Existing Subtitle'
              expect(existing_pub_reloaded.publication_type).to eq 'Journal Article'
              expect(existing_pub_reloaded.page_range).to eq 'existing range'
              expect(existing_pub_reloaded.volume).to eq 'existing volume'
              expect(existing_pub_reloaded.issue).to eq 'existing issue'
              expect(existing_pub_reloaded.journal).to eq new_journal
              expect(existing_pub_reloaded.issn).to eq 'existing issn'
              expect(existing_pub_reloaded.status).to eq 'existing status'
              expect(existing_pub_reloaded.published_on).to eq Date.new(2018, 8, 22)
              expect(existing_pub_reloaded.total_scopus_citations).to eq 2
              expect(existing_pub_reloaded.abstract).to eq 'existing abstract'
              expect(existing_pub_reloaded.visible).to eq false
              expect(existing_pub_reloaded.doi).to eq 'existing DOI'
            end
          end

          context "when the existing publication does not have a DOI" do
            let(:doi) { nil }
            it "updates only the Scopus citation count and DOI on the existing publication" do
              importer.call

              existing_pub_reloaded = existing_pub.reload

              expect(existing_pub_reloaded.title).to eq 'Existing Title'
              expect(existing_pub_reloaded.secondary_title).to eq 'Existing Subtitle'
              expect(existing_pub_reloaded.publication_type).to eq 'Journal Article'
              expect(existing_pub_reloaded.page_range).to eq 'existing range'
              expect(existing_pub_reloaded.volume).to eq 'existing volume'
              expect(existing_pub_reloaded.issue).to eq 'existing issue'
              expect(existing_pub_reloaded.journal).to eq new_journal
              expect(existing_pub_reloaded.issn).to eq 'existing issn'
              expect(existing_pub_reloaded.status).to eq 'existing status'
              expect(existing_pub_reloaded.published_on).to eq Date.new(2018, 8, 22)
              expect(existing_pub_reloaded.total_scopus_citations).to eq 2
              expect(existing_pub_reloaded.abstract).to eq 'existing abstract'
              expect(existing_pub_reloaded.visible).to eq false
              expect(existing_pub_reloaded.doi).to eq 'https://doi.org/10.1016/S0962-1849(05)80014-9'
            end
          end

          it "creates new publications with the correct data" do
            importer.call

            new_pub = found_pub2.publication

            expect(new_pub.title).to eq 'Third Test Publication With a Really Unique Title'
            expect(new_pub.secondary_title).to eq nil
            expect(new_pub.publication_type).to eq 'Academic Journal Article'
            expect(new_pub.page_range).to eq '665-680'
            expect(new_pub.volume).to eq '30'
            expect(new_pub.issue).to eq '3'
            expect(new_pub.journal).to eq journal
            expect(new_pub.issn).to eq '0272-4634'
            expect(new_pub.status).to eq 'Published'
            expect(new_pub.published_on).to eq Date.new(2010, 5, 1)
            expect(new_pub.total_scopus_citations).to eq 32
            expect(new_pub.abstract).to eq '<p>This is the third abstract.</p>'
            expect(new_pub.visible).to eq true
            expect(new_pub.doi).to eq nil
          end

          it "groups possible duplicates of new publication records" do
            expect { importer.call }.to change { DuplicatePublicationGroup.count }.by 1

            p2 = found_pub2.publication
            group = p2.duplicate_group
            
            expect(group.publications).to match_array [p2, duplicate_pub1, duplicate_pub2]
          end

          it "hides existing publications that might be duplicates" do
            importer.call

            p2 = found_pub2.publication

            expect(p2.visible).to eq true
            expect(duplicate_pub1.reload.visible).to eq false
            expect(duplicate_pub2.reload.visible).to eq false
          end
        end
      end
    end
  end
end
