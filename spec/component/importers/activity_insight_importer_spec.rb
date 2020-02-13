require 'component/component_spec_helper'

describe ActivityInsightImporter do
  let(:importer) { ActivityInsightImporter.new }

  before do
    allow(HTTParty).to receive(:get).with('https://webservices.digitalmeasures.com/login/service/v4/User',
                                          basic_auth: {username: 'test',
                                                       password: 'secret'}).and_return(
      File.read(Rails.root.join('spec', 'fixtures', 'activity_insight_users.xml')))

    allow(HTTParty).to receive(:get).with('https://webservices.digitalmeasures.com/login/service/v4/SchemaData/INDIVIDUAL-ACTIVITIES-University/USERNAME:ABC123',
                                          basic_auth: {username: 'test',
                                                       password: 'secret'}).and_return(
      File.read(Rails.root.join('spec', 'fixtures', 'activity_insight_user_abc123.xml'))
    )

    allow(HTTParty).to receive(:get).with('https://webservices.digitalmeasures.com/login/service/v4/SchemaData/INDIVIDUAL-ACTIVITIES-University/USERNAME:def45',
                                          basic_auth: {username: 'test',
                                                       password: 'secret'}).and_return(
      File.read(Rails.root.join('spec', 'fixtures', 'activity_insight_user_def45.xml'))
    )
  end
  describe '#call' do
    context "when the users being imported do not exist in the database" do
      it "creates new user records for each imported user" do
        expect { importer.call }.to change { User.count }.by 2

        u1 = User.find_by(webaccess_id: 'abc123')
        u2 = User.find_by(webaccess_id: 'def45')

        expect(u1.first_name).to eq 'Sally'
        expect(u1.middle_name).to be_nil
        expect(u1.last_name).to eq 'Testuser'
        expect(u1.activity_insight_identifier).to eq '1649499'
        expect(u1.penn_state_identifier).to eq '976567444'
        expect(u1.ai_building).to eq "Sally's Building"
        expect(u1.ai_room_number).to eq '123'
        expect(u1.ai_office_area_code).to eq 444
        expect(u1.ai_office_phone_1).to eq 555
        expect(u1.ai_office_phone_2).to eq 6666
        expect(u1.ai_fax_area_code).to eq 666
        expect(u1.ai_fax_1).to eq 777
        expect(u1.ai_fax_2).to eq 8888
        expect(u1.ai_website).to eq 'sociology.la.psu.edu/people/abc123'
        expect(u1.ai_bio).to eq "Sally's bio"
        expect(u1.ai_teaching_interests).to eq "Sally's teaching interests"
        expect(u1.ai_research_interests).to eq "Sally's research interests"

        expect(u2.first_name).to eq 'Bob'
        expect(u2.middle_name).to eq 'A.'
        expect(u2.last_name).to eq 'Tester'
        expect(u2.activity_insight_identifier).to eq '1949490'
        expect(u2.penn_state_identifier).to eq '9293659323'
      end

      context "when no included education history items exist in the database" do
        it "creates new education history items from the imported data" do
          expect { importer.call }.to change { EducationHistoryItem.count }.by 2

          i1 = EducationHistoryItem.find_by(activity_insight_identifier: '70766815232')
          i2 = EducationHistoryItem.find_by(activity_insight_identifier: '72346234523')
          user = User.find_by(webaccess_id: 'abc123')

          expect(i1.user).to eq user
          expect(i1.degree).to eq 'Ph D'
          expect(i1.explanation_of_other_degree).to be_nil
          expect(i1.institution).to eq 'The Pennsylvania State University'
          expect(i1.school).to eq 'Graduate School'
          expect(i1.location_of_institution).to eq 'University Park, PA'
          expect(i1.emphasis_or_major).to eq 'Sociology'
          expect(i1.supporting_areas_of_emphasis).to eq 'Demography'
          expect(i1.dissertation_or_thesis_title).to eq "Sally's Dissertation"
          expect(i1.is_highest_degree_earned).to eq 'Yes'
          expect(i1.honor_or_distinction).to be_nil
          expect(i1.description).to be_nil
          expect(i1.comments).to be_nil
          expect(i1.start_year).to eq 2006
          expect(i1.end_year).to eq 2009

          expect(i2.user).to eq user
          expect(i2.degree).to eq 'Other'
          expect(i2.explanation_of_other_degree).to eq 'Other degree'
          expect(i2.institution).to eq 'University of Pittsburgh'
          expect(i2.school).to eq 'Liberal Arts'
          expect(i2.location_of_institution).to eq 'Pittsburgh, PA'
          expect(i2.emphasis_or_major).to eq 'Psychology'
          expect(i2.supporting_areas_of_emphasis).to be_nil
          expect(i2.dissertation_or_thesis_title).to be_nil
          expect(i2.is_highest_degree_earned).to eq 'No'
          expect(i2.honor_or_distinction).to eq 'summa cum laude'
          expect(i2.description).to eq 'A description'
          expect(i2.comments).to eq 'Some comments'
          expect(i2.start_year).to eq 2000
          expect(i2.end_year).to eq 2004
        end
      end
      context "when an included education history item exists in the database" do
        let(:other_user) { create :user }
        before do
          create :education_history_item,
                 activity_insight_identifier: '70766815232',
                 user: other_user,
                 degree: 'Existing Degree',
                 explanation_of_other_degree: 'Existing Explanation',
                 institution: 'Existing Institution',
                 school: 'Existing School',
                 location_of_institution: 'Existing Location',
                 emphasis_or_major: 'Existing Major',
                 supporting_areas_of_emphasis: 'Existing Areas',
                 dissertation_or_thesis_title: 'Existing Title',
                 is_highest_degree_earned: 'No',
                 honor_or_distinction: 'Existing Honor',
                 description: 'Existing Description',
                 comments: 'Existing Comments',
                 start_year: '1990',
                 end_year: '1995'
        end

        it "creates any new items and updates the existing item" do
          expect { importer.call }.to change { EducationHistoryItem.count }.by 1

          i1 = EducationHistoryItem.find_by(activity_insight_identifier: '70766815232')
          i2 = EducationHistoryItem.find_by(activity_insight_identifier: '72346234523')
          user = User.find_by(webaccess_id: 'abc123')

          expect(i1.user).to eq user
          expect(i1.degree).to eq 'Ph D'
          expect(i1.explanation_of_other_degree).to be_nil
          expect(i1.institution).to eq 'The Pennsylvania State University'
          expect(i1.school).to eq 'Graduate School'
          expect(i1.location_of_institution).to eq 'University Park, PA'
          expect(i1.emphasis_or_major).to eq 'Sociology'
          expect(i1.supporting_areas_of_emphasis).to eq 'Demography'
          expect(i1.dissertation_or_thesis_title).to eq "Sally's Dissertation"
          expect(i1.is_highest_degree_earned).to eq 'Yes'
          expect(i1.honor_or_distinction).to be_nil
          expect(i1.description).to be_nil
          expect(i1.comments).to be_nil
          expect(i1.start_year).to eq 2006
          expect(i1.end_year).to eq 2009

          expect(i2.user).to eq user
          expect(i2.degree).to eq 'Other'
          expect(i2.explanation_of_other_degree).to eq 'Other degree'
          expect(i2.institution).to eq 'University of Pittsburgh'
          expect(i2.school).to eq 'Liberal Arts'
          expect(i2.location_of_institution).to eq 'Pittsburgh, PA'
          expect(i2.emphasis_or_major).to eq 'Psychology'
          expect(i2.supporting_areas_of_emphasis).to be_nil
          expect(i2.dissertation_or_thesis_title).to be_nil
          expect(i2.is_highest_degree_earned).to eq 'No'
          expect(i2.honor_or_distinction).to eq 'summa cum laude'
          expect(i2.description).to eq 'A description'
          expect(i2.comments).to eq 'Some comments'
          expect(i2.start_year).to eq 2000
          expect(i2.end_year).to eq 2004
        end
      end

      context "when no included presentations exist in the database" do
        it "creates new presentations from the imported data" do
          expect { importer.call }.to change { Presentation.count }.by 2

          p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
          p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

          expect(p1.title).to eq "Sally's ASA Presentation"
          expect(p1.name).to eq 'Annual Meeting of the American Sociological Association'
          expect(p1.organization).to eq 'Test Organization'
          expect(p1.location).to eq 'Las Vegas, NV'
          expect(p1.presentation_type).to eq 'Roundtable Discussion'
          expect(p1.meet_type).to eq 'Academic'
          expect(p1.scope).to eq 'International'
          expect(p1.attendance).to eq 500
          expect(p1.refereed).to eq 'Yes'
          expect(p1.abstract).to eq 'An abstract'
          expect(p1.comment).to eq 'Some comments'
          expect(p1.visible).to eq true

          expect(p2.title).to eq "Sally's PAA Presentation"
          expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
          expect(p2.organization).to be_nil
          expect(p2.location).to eq 'San Diego'
          expect(p2.presentation_type).to eq 'Papers and Presentations'
          expect(p2.meet_type).to eq 'Academic'
          expect(p2.scope).to eq 'International'
          expect(p2.attendance).to be_nil
          expect(p2.refereed).to eq 'No'
          expect(p2.abstract).to eq 'Another abstract'
          expect(p2.comment).to be_nil
          expect(p2.visible).to eq true
        end

        context "when no included presentation contributions exist in the database" do
          it "creates new presentation contributions from the imported data where user IDs are present" do
            expect { importer.call }.to change { PresentationContribution.count }.by 2

            p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
            p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

            u = User.find_by(activity_insight_identifier: '1649499')

            c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
            c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

            expect(c1.user).to eq u
            expect(c1.presentation).to eq p1
            expect(c1.role).to eq 'Presenter and Author'
            expect(c1.position).to eq 1

            expect(c2.user).to eq u
            expect(c2.presentation).to eq p2
            expect(c2.role).to eq 'Author Only'
            expect(c2.position).to eq 2
          end
        end
        context "when an included presentation contribution exists in the database" do
          let(:other_user) { create :user }
          let(:other_presentation) { create :presentation }
          before do
            create :presentation_contribution,
                   activity_insight_identifier: '83890556929',
                   user: other_user,
                   presentation: other_presentation,
                   role: 'Existing Role'
          end
          it "creates any new contributions and updates the existing contribution" do
            expect { importer.call }.to change { PresentationContribution.count }.by 1

            p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
            p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

            u = User.find_by(activity_insight_identifier: '1649499')

            c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
            c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

            expect(c1.user).to eq u
            expect(c1.presentation).to eq p1
            expect(c1.role).to eq 'Presenter and Author'
            expect(c1.position).to eq 1

            expect(c2.user).to eq u
            expect(c2.presentation).to eq p2
            expect(c2.role).to eq 'Author Only'
            expect(c2.position).to eq 2
          end
        end
      end
      context "when an included presentation exists in the database" do
        before do
          create :presentation,
                 activity_insight_identifier: '83890556928',
                 updated_by_user_at: updated,
                 title: 'Existing Title',
                 visible: false
        end

        context "when the existing presentation has been updated by an admin" do
          let(:updated) { Time.zone.now }
          it "creates any new presentations and does not update the existing presentation" do
            expect { importer.call }.to change { Presentation.count }.by 1

            p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
            p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

            expect(p1.title).to eq "Existing Title"
            expect(p1.name).to be_nil
            expect(p1.organization).to be_nil
            expect(p1.location).to be_nil
            expect(p1.presentation_type).to be_nil
            expect(p1.meet_type).to be_nil
            expect(p1.scope).to be_nil
            expect(p1.attendance).to be_nil
            expect(p1.refereed).to be_nil
            expect(p1.abstract).to be_nil
            expect(p1.comment).to be_nil
            expect(p1.visible).to eq false

            expect(p2.title).to eq "Sally's PAA Presentation"
            expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
            expect(p2.organization).to be_nil
            expect(p2.location).to eq 'San Diego'
            expect(p2.presentation_type).to eq 'Papers and Presentations'
            expect(p2.meet_type).to eq 'Academic'
            expect(p2.scope).to eq 'International'
            expect(p2.attendance).to be_nil
            expect(p2.refereed).to eq 'No'
            expect(p2.abstract).to eq 'Another abstract'
            expect(p2.comment).to be_nil
            expect(p2.visible).to eq true
          end

          context "when no included presentation contributions exist in the database" do
            it "creates new presentation contributions from the imported data where user IDs are present" do
              expect { importer.call }.to change { PresentationContribution.count }.by 2

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              u = User.find_by(activity_insight_identifier: '1649499')

              c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
              c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

              expect(c1.user).to eq u
              expect(c1.presentation).to eq p1
              expect(c1.role).to eq 'Presenter and Author'
              expect(c1.position).to eq 1

              expect(c2.user).to eq u
              expect(c2.presentation).to eq p2
              expect(c2.role).to eq 'Author Only'
              expect(c2.position).to eq 2
            end
          end
          context "when an included presentation contribution exists in the database" do
            let(:other_user) { create :user }
            let(:other_presentation) { create :presentation }
            before do
              create :presentation_contribution,
                     activity_insight_identifier: '83890556929',
                     user: other_user,
                     presentation: other_presentation,
                     role: 'Existing Role'
            end
            it "creates any new contributions and updates the existing contribution" do
              expect { importer.call }.to change { PresentationContribution.count }.by 1

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              u = User.find_by(activity_insight_identifier: '1649499')

              c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
              c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

              expect(c1.user).to eq u
              expect(c1.presentation).to eq p1
              expect(c1.role).to eq 'Presenter and Author'
              expect(c1.position).to eq 1

              expect(c2.user).to eq u
              expect(c2.presentation).to eq p2
              expect(c2.role).to eq 'Author Only'
              expect(c2.position).to eq 2
            end
          end
        end

        context "when the existing presentation has not been updated by an admin" do
          let(:updated) { nil }
          it "creates any new presentations and updates the existing presentation" do
            expect { importer.call }.to change { Presentation.count }.by 1

            p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
            p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

            expect(p1.title).to eq "Sally's ASA Presentation"
            expect(p1.name).to eq 'Annual Meeting of the American Sociological Association'
            expect(p1.organization).to eq 'Test Organization'
            expect(p1.location).to eq 'Las Vegas, NV'
            expect(p1.presentation_type).to eq 'Roundtable Discussion'
            expect(p1.meet_type).to eq 'Academic'
            expect(p1.scope).to eq 'International'
            expect(p1.attendance).to eq 500
            expect(p1.refereed).to eq 'Yes'
            expect(p1.abstract).to eq 'An abstract'
            expect(p1.comment).to eq 'Some comments'
            expect(p1.visible).to eq false

            expect(p2.title).to eq "Sally's PAA Presentation"
            expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
            expect(p2.organization).to be_nil
            expect(p2.location).to eq 'San Diego'
            expect(p2.presentation_type).to eq 'Papers and Presentations'
            expect(p2.meet_type).to eq 'Academic'
            expect(p2.scope).to eq 'International'
            expect(p2.attendance).to be_nil
            expect(p2.refereed).to eq 'No'
            expect(p2.abstract).to eq 'Another abstract'
            expect(p2.comment).to be_nil
            expect(p2.visible).to eq true
          end

          context "when no included presentation contributions exist in the database" do
            it "creates new presentation contributions from the imported data where user IDs are present" do
              expect { importer.call }.to change { PresentationContribution.count }.by 2

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              u = User.find_by(activity_insight_identifier: '1649499')

              c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
              c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

              expect(c1.user).to eq u
              expect(c1.presentation).to eq p1
              expect(c1.role).to eq 'Presenter and Author'
              expect(c1.position).to eq 1

              expect(c2.user).to eq u
              expect(c2.presentation).to eq p2
              expect(c2.role).to eq 'Author Only'
              expect(c2.position).to eq 2
            end
          end
          context "when an included presentation contribution exists in the database" do
            let(:other_user) { create :user }
            let(:other_presentation) { create :presentation }
            before do
              create :presentation_contribution,
                     activity_insight_identifier: '83890556929',
                     user: other_user,
                     presentation: other_presentation,
                     role: 'Existing Role'
            end
            it "creates any new contributions and updates the existing contribution" do
              expect { importer.call }.to change { PresentationContribution.count }.by 1

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              u = User.find_by(activity_insight_identifier: '1649499')

              c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
              c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

              expect(c1.user).to eq u
              expect(c1.presentation).to eq p1
              expect(c1.role).to eq 'Presenter and Author'
              expect(c1.position).to eq 1

              expect(c2.user).to eq u
              expect(c2.presentation).to eq p2
              expect(c2.role).to eq 'Author Only'
              expect(c2.position).to eq 2
            end
          end
        end
      end

      context "when no included performances exist in the database" do
        it "creates new performances from the imported data" do
          expect { importer.call }.to change { Performance.count }.by 2

          p1 = Performance.find_by(activity_insight_id: '126500763648')
          p2 = Performance.find_by(activity_insight_id: '13745734789')

          expect(p1.title).to eq "Sally's Documentary"
          expect(p1.performance_type).to eq "Film - Documentary"
          expect(p1.sponsor).to eq "Test Sponsor"
          expect(p1.description).to eq "A description"
          expect(p1.group_name).to eq "Test Group"
          expect(p1.location).to eq "University Park, PA"
          expect(p1.delivery_type).to eq "Invitation"
          expect(p1.scope).to eq "Regional"
          expect(p1.start_on).to eq Date.new(2009, 2, 1)
          expect(p1.end_on).to eq Date.new(2009, 8, 1)
          expect(p1.visible).to eq true

          expect(p2.title).to eq "Sally's Film"
          expect(p2.performance_type).to eq "Film - Other"
          expect(p2.sponsor).to eq "Another Sponsor"
          expect(p2.description).to eq "Another description"
          expect(p2.group_name).to eq "Another Group"
          expect(p2.location).to eq "Philadelphia, PA"
          expect(p2.delivery_type).to be_nil
          expect(p2.scope).to eq "Local"
          expect(p2.start_on).to eq Date.new(2000, 2, 1)
          expect(p2.end_on).to eq Date.new(2000, 8, 1)
          expect(p2.visible).to eq true
        end

        context "when no included user performances exist in the database" do
          it "creates new user performances from the imported data" do
            expect { importer.call }.to change { UserPerformance.count }.by 2

            p1 = Performance.find_by(activity_insight_id: '126500763648')
            p2 = Performance.find_by(activity_insight_id: '13745734789')

            u = User.find_by(activity_insight_identifier: '1649499')

            up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
            up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

            expect(up1.user).to eq u
            expect(up1.performance).to eq p1
            expect(up1.contribution).to eq 'Director'

            expect(up2.user).to eq u
            expect(up2.performance).to eq p2
            expect(up2.contribution).to eq 'Writer'
          end
        end

        context "when an included user performance exists in the database" do
          let(:other_user) { create :user }
          let(:other_performance) { create :performance }
          before do
            create :user_performance,
                   activity_insight_id: '126500763649',
                   user: other_user,
                   performance: other_performance,
                   contribution: 'Existing Contribution'
          end
          it "creates any new user performances and updates the existing user performances" do
            expect { importer.call }.to change { UserPerformance.count }.by 1

            p1 = Performance.find_by(activity_insight_id: '126500763648')
            p2 = Performance.find_by(activity_insight_id: '13745734789')

            u = User.find_by(activity_insight_identifier: '1649499')

            up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
            up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

            expect(up1.user).to eq u
            expect(up1.performance).to eq p1
            expect(up1.contribution).to eq 'Director'

            expect(up2.user).to eq u
            expect(up2.performance).to eq p2
            expect(up2.contribution).to eq 'Writer'
          end
        end
      end

      context "when an included performance exists in the database" do
        before do
          create :performance,
                 activity_insight_id: '126500763648',
                 updated_by_user_at: updated,
                 title: 'Existing Title',
                 performance_type: nil,
                 sponsor: nil,
                 description: nil,
                 group_name: nil,
                 location: nil,
                 delivery_type: nil,
                 scope: nil,
                 start_on: nil,
                 end_on: nil,
                 visible: false
        end
        context "when the existing performance has been updated by an admin" do
          let(:updated) { Time.zone.now }
          it "creates any new performances and does not update the existing performance" do
            expect { importer.call }.to change { Performance.count }.by 1

            p1 = Performance.find_by(activity_insight_id: '126500763648')
            p2 = Performance.find_by(activity_insight_id: '13745734789')

            expect(p1.title).to eq "Existing Title"
            expect(p1.performance_type).to be_nil
            expect(p1.sponsor).to be_nil
            expect(p1.description).to be_nil
            expect(p1.group_name).to be_nil
            expect(p1.location).to be_nil
            expect(p1.delivery_type).to be_nil
            expect(p1.scope).to be_nil
            expect(p1.start_on).to be_nil
            expect(p1.end_on).to be_nil
            expect(p1.visible).to eq false

            expect(p2.title).to eq "Sally's Film"
            expect(p2.performance_type).to eq "Film - Other"
            expect(p2.sponsor).to eq "Another Sponsor"
            expect(p2.description).to eq "Another description"
            expect(p2.group_name).to eq "Another Group"
            expect(p2.location).to eq "Philadelphia, PA"
            expect(p2.delivery_type).to be_nil
            expect(p2.scope).to eq "Local"
            expect(p2.start_on).to eq Date.new(2000, 2, 1)
            expect(p2.end_on).to eq Date.new(2000, 8, 1)
            expect(p2.visible).to eq true
          end


          context "when no included user performances exist in the database" do
            it "creates new user performances from the imported data" do
              expect { importer.call }.to change { UserPerformance.count }.by 2

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              u = User.find_by(activity_insight_identifier: '1649499')

              up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
              up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

              expect(up1.user).to eq u
              expect(up1.performance).to eq p1
              expect(up1.contribution).to eq 'Director'

              expect(up2.user).to eq u
              expect(up2.performance).to eq p2
              expect(up2.contribution).to eq 'Writer'
            end
          end

          context "when an included user performance exists in the database" do
            let(:other_user) { create :user }
            let(:other_performance) { create :performance }
            before do
              create :user_performance,
                     activity_insight_id: '126500763649',
                     user: other_user,
                     performance: other_performance,
                     contribution: 'Existing Contribution'
            end
            it "creates any new user performances and updates the existing user performances" do
              expect { importer.call }.to change { UserPerformance.count }.by 1

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              u = User.find_by(activity_insight_identifier: '1649499')

              up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
              up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

              expect(up1.user).to eq u
              expect(up1.performance).to eq p1
              expect(up1.contribution).to eq 'Director'

              expect(up2.user).to eq u
              expect(up2.performance).to eq p2
              expect(up2.contribution).to eq 'Writer'
            end
          end
        end

        context "when the existing performance has not been updated by an admin" do
          let(:updated) { nil }
          it "creates any new performances and updates the existing performance" do
            expect { importer.call }.to change { Performance.count }.by 1

            p1 = Performance.find_by(activity_insight_id: '126500763648')
            p2 = Performance.find_by(activity_insight_id: '13745734789')

            expect(p1.title).to eq "Sally's Documentary"
            expect(p1.performance_type).to eq "Film - Documentary"
            expect(p1.sponsor).to eq "Test Sponsor"
            expect(p1.description).to eq "A description"
            expect(p1.group_name).to eq "Test Group"
            expect(p1.location).to eq "University Park, PA"
            expect(p1.delivery_type).to eq "Invitation"
            expect(p1.scope).to eq "Regional"
            expect(p1.start_on). to eq Date.new(2009, 2, 1)
            expect(p1.end_on).to eq Date.new(2009, 8, 1)
            expect(p1.visible).to eq false

            expect(p2.title).to eq "Sally's Film"
            expect(p2.performance_type).to eq "Film - Other"
            expect(p2.sponsor).to eq "Another Sponsor"
            expect(p2.description).to eq "Another description"
            expect(p2.group_name).to eq "Another Group"
            expect(p2.location).to eq "Philadelphia, PA"
            expect(p2.delivery_type).to be_nil
            expect(p2.scope).to eq "Local"
            expect(p2.start_on).to eq Date.new(2000, 2, 1)
            expect(p2.end_on).to eq Date.new(2000, 8, 1)
            expect(p2.visible).to eq true
          end


          context "when no included user performances exist in the database" do
            it "creates new user performances from the imported data" do
              expect { importer.call }.to change { UserPerformance.count }.by 2

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              u = User.find_by(activity_insight_identifier: '1649499')

              up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
              up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

              expect(up1.user).to eq u
              expect(up1.performance).to eq p1
              expect(up1.contribution).to eq 'Director'

              expect(up2.user).to eq u
              expect(up2.performance).to eq p2
              expect(up2.contribution).to eq 'Writer'
            end
          end

          context "when an included user performance exists in the database" do
            let(:other_user) { create :user }
            let(:other_performance) { create :performance }
            before do
              create :user_performance,
                     activity_insight_id: '126500763649',
                     user: other_user,
                     performance: other_performance,
                     contribution: 'Existing Contribution'
            end
            it "creates any new user performances and updates the existing user performances" do
              expect { importer.call }.to change { UserPerformance.count }.by 1

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              u = User.find_by(activity_insight_identifier: '1649499')

              up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
              up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

              expect(up1.user).to eq u
              expect(up1.performance).to eq p1
              expect(up1.contribution).to eq 'Director'

              expect(up2.user).to eq u
              expect(up2.performance).to eq p2
              expect(up2.contribution).to eq 'Writer'
            end
          end
        end
      end

      context "when no included publications exist in the database" do
        it "creates a new publication import record for every published journal article in the imported data" do
          expect { importer.call }.to change { PublicationImport.count }.by 3
        end

        it "creates a new publication record for every published journal article in the imported data" do
          expect { importer.call }.to change { Publication.count }.by 3
        end
        
        it "saves the correct data to the new publication records" do
          importer.call

          p1 = PublicationImport.find_by(source: 'Activity Insight',
                                         source_identifier: '190706413568').publication
          p2 = PublicationImport.find_by(source: 'Activity Insight',
                                         source_identifier: '171620739072').publication
          p3 = PublicationImport.find_by(source: 'Activity Insight',
                                         source_identifier: '92747188475').publication

          expect(p1.title).to eq 'First Test Publication'
          expect(p1.publication_type).to eq 'Journal Article'
          expect(p1.journal_title).to eq 'Test Journal 1'
          expect(p1.publisher).to eq 'Test Publisher 1'
          expect(p1.secondary_title).to eq 'Subtitle 1'
          expect(p1.status).to eq 'Published'
          expect(p1.volume).to eq '9'
          expect(p1.issue).to eq '5'
          expect(p1.edition).to eq '10'
          expect(p1.page_range).to eq '1633-1646'
          expect(p1.url).to eq 'https://example.com/publication1'
          expect(p1.issn).to eq '6532-1836'
          expect(p1.abstract).to eq 'First publication abstract.'
          expect(p1.authors_et_al).to eq true
          expect(p1.published_on).to eq Date.new(2019, 1, 1)
          expect(p1.visible).to eq true
          expect(p1.updated_by_user_at).to eq nil
          expect(p1.doi).to eq nil

          expect(p2.title).to eq 'Second Test Publication'
          expect(p2.publication_type).to eq 'Professional Journal Article'
          expect(p2.journal_title).to eq 'Test Jouranl 2'
          expect(p2.publisher).to eq nil
          expect(p2.secondary_title).to eq 'Second Pub Subtitle'
          expect(p2.status).to eq 'Published'
          expect(p2.volume).to eq '7'
          expect(p2.issue).to eq nil
          expect(p2.edition).to eq nil
          expect(p2.page_range).to eq nil
          expect(p2.url).to eq 'https://doi.org/10.1001/amajethics.2019.239'
          expect(p2.issn).to eq nil
          expect(p2.abstract).to eq nil
          expect(p2.authors_et_al).to eq false
          expect(p2.published_on).to eq Date.new(2019, 1, 1)
          expect(p2.visible).to eq true
          expect(p2.updated_by_user_at).to eq nil
          expect(p2.doi).to eq 'https://doi.org/10.1001/amajethics.2019.239'

          expect(p3.title).to eq 'Fifth Test Publication'
          expect(p3.publication_type).to eq 'Academic Journal Article'
          expect(p3.journal_title).to eq 'Some Other Journal'
          expect(p3.publisher).to eq 'Some Other Publisher'
          expect(p3.secondary_title).to eq nil
          expect(p3.status).to eq 'Published'
          expect(p3.volume).to eq '17'
          expect(p3.issue).to eq '8'
          expect(p3.edition).to eq '4'
          expect(p3.page_range).to eq '1276-1288'
          expect(p3.url).to eq nil
          expect(p3.issn).to eq 'https://doi.org/10.1001/archderm.139.10.1363-g'
          expect(p3.abstract).to eq nil
          expect(p3.authors_et_al).to eq false
          expect(p3.published_on).to eq Date.new(2010, 1, 1)
          expect(p3.visible).to eq true
          expect(p3.updated_by_user_at).to eq nil
          expect(p3.doi).to eq 'https://doi.org/10.1001/archderm.139.10.1363-g'
        end
      end
      context "when an included publication exists in the database" do
        let!(:existing_import) { create :publication_import,
                                        source: 'Activity Insight',
                                        source_identifier: '171620739072',
                                        publication: existing_pub }
        let(:existing_pub) { create :publication,
                                    title: 'Existing Title',
                                    publication_type: 'Trade Journal Article',
                                    journal_title: 'Existing Journal',
                                    publisher: 'Existing Publisher',
                                    secondary_title: 'Existing Subtitle',
                                    status: 'Existing Status',
                                    volume: '111',
                                    issue: '222',
                                    edition: '333',
                                    page_range: '444-555',
                                    url: 'existing_url',
                                    issn: 'existing_ISSN',
                                    abstract: 'Existing abstract',
                                    authors_et_al: true,
                                    published_on: Date.new(1980, 1, 1),
                                    updated_by_user_at: timestamp,
                                    visible: false,
                                    doi: 'existing DOI' }
        context "when the existing publication has been modified by an admin user" do
          let(:timestamp) { Time.new(2018, 10, 10, 0, 0, 0) }

          it "creates a new publication import record for every new published journal article in the imported data" do
            expect { importer.call }.to change { PublicationImport.count }.by 2
          end
  
          it "creates a new publication record for every new published journal article in the imported data" do
            expect { importer.call }.to change { Publication.count }.by 2
          end
          
          it "saves the correct data to the new publication records and does not update the existing record" do
            importer.call
  
            p1 = PublicationImport.find_by(source: 'Activity Insight',
                                           source_identifier: '190706413568').publication
            p2 = PublicationImport.find_by(source: 'Activity Insight',
                                           source_identifier: '171620739072').publication
            p3 = PublicationImport.find_by(source: 'Activity Insight',
                                           source_identifier: '92747188475').publication
  
            expect(p1.title).to eq 'First Test Publication'
            expect(p1.publication_type).to eq 'Journal Article'
            expect(p1.journal_title).to eq 'Test Journal 1'
            expect(p1.publisher).to eq 'Test Publisher 1'
            expect(p1.secondary_title).to eq 'Subtitle 1'
            expect(p1.status).to eq 'Published'
            expect(p1.volume).to eq '9'
            expect(p1.issue).to eq '5'
            expect(p1.edition).to eq '10'
            expect(p1.page_range).to eq '1633-1646'
            expect(p1.url).to eq 'https://example.com/publication1'
            expect(p1.issn).to eq '6532-1836'
            expect(p1.abstract).to eq 'First publication abstract.'
            expect(p1.authors_et_al).to eq true
            expect(p1.published_on).to eq Date.new(2019, 1, 1)
            expect(p1.visible).to eq true
            expect(p1.updated_by_user_at).to eq nil
            expect(p1.doi).to eq nil
  
            expect(p2.title).to eq 'Existing Title'
            expect(p2.publication_type).to eq 'Trade Journal Article'
            expect(p2.journal_title).to eq 'Existing Journal'
            expect(p2.publisher).to eq 'Existing Publisher'
            expect(p2.secondary_title).to eq 'Existing Subtitle'
            expect(p2.status).to eq 'Existing Status'
            expect(p2.volume).to eq '111'
            expect(p2.issue).to eq '222'
            expect(p2.edition).to eq '333'
            expect(p2.page_range).to eq '444-555'
            expect(p2.url).to eq 'existing_url'
            expect(p2.issn).to eq 'existing_ISSN'
            expect(p2.abstract).to eq 'Existing abstract'
            expect(p2.authors_et_al).to eq true
            expect(p2.published_on).to eq Date.new(1980, 1, 1)
            expect(p2.visible).to eq false
            expect(p2.updated_by_user_at).to eq Time.new(2018, 10, 10, 0, 0, 0)
            expect(p2.doi).to eq 'existing DOI'
  
            expect(p3.title).to eq 'Fifth Test Publication'
            expect(p3.publication_type).to eq 'Academic Journal Article'
            expect(p3.journal_title).to eq 'Some Other Journal'
            expect(p3.publisher).to eq 'Some Other Publisher'
            expect(p3.secondary_title).to eq nil
            expect(p3.status).to eq 'Published'
            expect(p3.volume).to eq '17'
            expect(p3.issue).to eq '8'
            expect(p3.edition).to eq '4'
            expect(p3.page_range).to eq '1276-1288'
            expect(p3.url).to eq nil
            expect(p3.issn).to eq 'https://doi.org/10.1001/archderm.139.10.1363-g'
            expect(p3.abstract).to eq nil
            expect(p3.authors_et_al).to eq false
            expect(p3.published_on).to eq Date.new(2010, 1, 1)
            expect(p3.visible).to eq true
            expect(p3.updated_by_user_at).to eq nil
            expect(p3.doi).to eq 'https://doi.org/10.1001/archderm.139.10.1363-g'
          end
        end

        context "when the existing publication has not been modified by an admin user" do
          let(:timestamp) { nil }

          it "creates a new publication import record for every new published journal article in the imported data" do
            expect { importer.call }.to change { PublicationImport.count }.by 2
          end
  
          it "creates a new publication record for every new published journal article in the imported data" do
            expect { importer.call }.to change { Publication.count }.by 2
          end
          
          it "saves the correct data to the new publication records and updates the existing record" do
            importer.call
  
            p1 = PublicationImport.find_by(source: 'Activity Insight',
                                           source_identifier: '190706413568').publication
            p2 = PublicationImport.find_by(source: 'Activity Insight',
                                           source_identifier: '171620739072').publication
            p3 = PublicationImport.find_by(source: 'Activity Insight',
                                           source_identifier: '92747188475').publication
  
            expect(p1.title).to eq 'First Test Publication'
            expect(p1.publication_type).to eq 'Journal Article'
            expect(p1.journal_title).to eq 'Test Journal 1'
            expect(p1.publisher).to eq 'Test Publisher 1'
            expect(p1.secondary_title).to eq 'Subtitle 1'
            expect(p1.status).to eq 'Published'
            expect(p1.volume).to eq '9'
            expect(p1.issue).to eq '5'
            expect(p1.edition).to eq '10'
            expect(p1.page_range).to eq '1633-1646'
            expect(p1.url).to eq 'https://example.com/publication1'
            expect(p1.issn).to eq '6532-1836'
            expect(p1.abstract).to eq 'First publication abstract.'
            expect(p1.authors_et_al).to eq true
            expect(p1.published_on).to eq Date.new(2019, 1, 1)
            expect(p1.visible).to eq true
            expect(p1.updated_by_user_at).to eq nil
            expect(p1.doi).to eq nil
  
            expect(p2.title).to eq 'Second Test Publication'
            expect(p2.publication_type).to eq 'Professional Journal Article'
            expect(p2.journal_title).to eq 'Test Jouranl 2'
            expect(p2.publisher).to eq nil
            expect(p2.secondary_title).to eq 'Second Pub Subtitle'
            expect(p2.status).to eq 'Published'
            expect(p2.volume).to eq '7'
            expect(p2.issue).to eq nil
            expect(p2.edition).to eq nil
            expect(p2.page_range).to eq nil
            expect(p2.url).to eq 'https://doi.org/10.1001/amajethics.2019.239'
            expect(p2.issn).to eq nil
            expect(p2.abstract).to eq nil
            expect(p2.authors_et_al).to eq false
            expect(p2.published_on).to eq Date.new(2019, 1, 1)
            expect(p2.visible).to eq false
            expect(p2.updated_by_user_at).to eq nil
            expect(p2.doi).to eq 'https://doi.org/10.1001/amajethics.2019.239'
  
            expect(p3.title).to eq 'Fifth Test Publication'
            expect(p3.publication_type).to eq 'Academic Journal Article'
            expect(p3.journal_title).to eq 'Some Other Journal'
            expect(p3.publisher).to eq 'Some Other Publisher'
            expect(p3.secondary_title).to eq nil
            expect(p3.status).to eq 'Published'
            expect(p3.volume).to eq '17'
            expect(p3.issue).to eq '8'
            expect(p3.edition).to eq '4'
            expect(p3.page_range).to eq '1276-1288'
            expect(p3.url).to eq nil
            expect(p3.issn).to eq 'https://doi.org/10.1001/archderm.139.10.1363-g'
            expect(p3.abstract).to eq nil
            expect(p3.authors_et_al).to eq false
            expect(p3.published_on).to eq Date.new(2010, 1, 1)
            expect(p3.visible).to eq true
            expect(p3.updated_by_user_at).to eq nil
            expect(p3.doi).to eq 'https://doi.org/10.1001/archderm.139.10.1363-g'
          end
        end
      end
    end




    context "when a user that is being imported already exists in the database" do
      before do
        create :user,
               webaccess_id: 'abc123',
               first_name: 'Existing',
               middle_name: 'T.',
               last_name: 'User',
               activity_insight_identifier: '1234567',
               penn_state_identifier: '999999999',
               updated_by_user_at: updated
      end
      context "when the existing user has been updated by an admin" do
        let(:updated) { Time.zone.now }

        it "creates any new users and does not update the existing user" do
          expect { importer.call }.to change { User.count }.by 1

          u1 = User.find_by(webaccess_id: 'abc123')
          u2 = User.find_by(webaccess_id: 'def45')

          expect(u1.first_name).to eq 'Existing'
          expect(u1.middle_name).to eq 'T.'
          expect(u1.last_name).to eq 'User'
          expect(u1.activity_insight_identifier).to eq '1234567'
          expect(u1.penn_state_identifier).to eq '999999999'
          expect(u1.ai_building).to be_nil
          expect(u1.ai_room_number).to be_nil
          expect(u1.ai_office_area_code).to be_nil
          expect(u1.ai_office_phone_1).to be_nil
          expect(u1.ai_office_phone_2).to be_nil
          expect(u1.ai_fax_area_code).to be_nil
          expect(u1.ai_fax_1).to be_nil
          expect(u1.ai_fax_2).to be_nil
          expect(u1.ai_website).to be_nil
          expect(u1.ai_bio).to be_nil
          expect(u1.ai_teaching_interests).to be_nil
          expect(u1.ai_research_interests).to be_nil

          expect(u2.first_name).to eq 'Bob'
          expect(u2.middle_name).to eq 'A.'
          expect(u2.last_name).to eq 'Tester'
          expect(u2.activity_insight_identifier).to eq '1949490'
          expect(u2.penn_state_identifier).to eq '9293659323'
        end

        context "when no included education history items exist in the database" do
          it "creates new education history items from the imported data" do
            expect { importer.call }.to change { EducationHistoryItem.count }.by 2

            i1 = EducationHistoryItem.find_by(activity_insight_identifier: '70766815232')
            i2 = EducationHistoryItem.find_by(activity_insight_identifier: '72346234523')
            user = User.find_by(webaccess_id: 'abc123')

            expect(i1.user).to eq user
            expect(i1.degree).to eq 'Ph D'
            expect(i1.explanation_of_other_degree).to be_nil
            expect(i1.institution).to eq 'The Pennsylvania State University'
            expect(i1.school).to eq 'Graduate School'
            expect(i1.location_of_institution).to eq 'University Park, PA'
            expect(i1.emphasis_or_major).to eq 'Sociology'
            expect(i1.supporting_areas_of_emphasis).to eq 'Demography'
            expect(i1.dissertation_or_thesis_title).to eq "Sally's Dissertation"
            expect(i1.is_highest_degree_earned).to eq 'Yes'
            expect(i1.honor_or_distinction).to be_nil
            expect(i1.description).to be_nil
            expect(i1.comments).to be_nil
            expect(i1.start_year).to eq 2006
            expect(i1.end_year).to eq 2009

            expect(i2.user).to eq user
            expect(i2.degree).to eq 'Other'
            expect(i2.explanation_of_other_degree).to eq 'Other degree'
            expect(i2.institution).to eq 'University of Pittsburgh'
            expect(i2.school).to eq 'Liberal Arts'
            expect(i2.location_of_institution).to eq 'Pittsburgh, PA'
            expect(i2.emphasis_or_major).to eq 'Psychology'
            expect(i2.supporting_areas_of_emphasis).to be_nil
            expect(i2.dissertation_or_thesis_title).to be_nil
            expect(i2.is_highest_degree_earned).to eq 'No'
            expect(i2.honor_or_distinction).to eq 'summa cum laude'
            expect(i2.description).to eq 'A description'
            expect(i2.comments).to eq 'Some comments'
            expect(i2.start_year).to eq 2000
            expect(i2.end_year).to eq 2004
          end
        end
        context "when an included education history item exists in the database" do
          let(:other_user) { create :user }
          before do
            create :education_history_item,
                   activity_insight_identifier: '70766815232',
                   user: other_user,
                   degree: 'Existing Degree',
                   explanation_of_other_degree: 'Existing Explanation',
                   institution: 'Existing Institution',
                   school: 'Existing School',
                   location_of_institution: 'Existing Location',
                   emphasis_or_major: 'Existing Major',
                   supporting_areas_of_emphasis: 'Existing Areas',
                   dissertation_or_thesis_title: 'Existing Title',
                   is_highest_degree_earned: 'No',
                   honor_or_distinction: 'Existing Honor',
                   description: 'Existing Description',
                   comments: 'Existing Comments',
                   start_year: '1990',
                   end_year: '1995'
          end

          it "creates any new items and updates the existing item" do
            expect { importer.call }.to change { EducationHistoryItem.count }.by 1

            i1 = EducationHistoryItem.find_by(activity_insight_identifier: '70766815232')
            i2 = EducationHistoryItem.find_by(activity_insight_identifier: '72346234523')
            user = User.find_by(webaccess_id: 'abc123')

            expect(i1.user).to eq user
            expect(i1.degree).to eq 'Ph D'
            expect(i1.explanation_of_other_degree).to be_nil
            expect(i1.institution).to eq 'The Pennsylvania State University'
            expect(i1.school).to eq 'Graduate School'
            expect(i1.location_of_institution).to eq 'University Park, PA'
            expect(i1.emphasis_or_major).to eq 'Sociology'
            expect(i1.supporting_areas_of_emphasis).to eq 'Demography'
            expect(i1.dissertation_or_thesis_title).to eq "Sally's Dissertation"
            expect(i1.is_highest_degree_earned).to eq 'Yes'
            expect(i1.honor_or_distinction).to be_nil
            expect(i1.description).to be_nil
            expect(i1.comments).to be_nil
            expect(i1.start_year).to eq 2006
            expect(i1.end_year).to eq 2009

            expect(i2.user).to eq user
            expect(i2.degree).to eq 'Other'
            expect(i2.explanation_of_other_degree).to eq 'Other degree'
            expect(i2.institution).to eq 'University of Pittsburgh'
            expect(i2.school).to eq 'Liberal Arts'
            expect(i2.location_of_institution).to eq 'Pittsburgh, PA'
            expect(i2.emphasis_or_major).to eq 'Psychology'
            expect(i2.supporting_areas_of_emphasis).to be_nil
            expect(i2.dissertation_or_thesis_title).to be_nil
            expect(i2.is_highest_degree_earned).to eq 'No'
            expect(i2.honor_or_distinction).to eq 'summa cum laude'
            expect(i2.description).to eq 'A description'
            expect(i2.comments).to eq 'Some comments'
            expect(i2.start_year).to eq 2000
            expect(i2.end_year).to eq 2004
          end
        end

        context "when no included presentations exist in the database" do
          it "creates new presentations from the imported data" do
            expect { importer.call }.to change { Presentation.count }.by 2

            p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
            p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

            expect(p1.title).to eq "Sally's ASA Presentation"
            expect(p1.name).to eq 'Annual Meeting of the American Sociological Association'
            expect(p1.organization).to eq 'Test Organization'
            expect(p1.location).to eq 'Las Vegas, NV'
            expect(p1.presentation_type).to eq 'Roundtable Discussion'
            expect(p1.meet_type).to eq 'Academic'
            expect(p1.scope).to eq 'International'
            expect(p1.attendance).to eq 500
            expect(p1.refereed).to eq 'Yes'
            expect(p1.abstract).to eq 'An abstract'
            expect(p1.comment).to eq 'Some comments'
            expect(p1.visible).to eq true

            expect(p2.title).to eq "Sally's PAA Presentation"
            expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
            expect(p2.organization).to be_nil
            expect(p2.location).to eq 'San Diego'
            expect(p2.presentation_type).to eq 'Papers and Presentations'
            expect(p2.meet_type).to eq 'Academic'
            expect(p2.scope).to eq 'International'
            expect(p2.attendance).to be_nil
            expect(p2.refereed).to eq 'No'
            expect(p2.abstract).to eq 'Another abstract'
            expect(p2.comment).to be_nil
            expect(p2.visible).to eq true
          end

          context "when no included presentation contributions exist in the database" do
            context "when a user that matches the contribution exists" do
              let!(:user) { create :user, activity_insight_identifier: '1649499' }

              it "creates new presentation contributions from the imported data where user IDs are present" do
                expect { importer.call }.to change { PresentationContribution.count }.by 2

                p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                expect(c1.user).to eq user
                expect(c1.presentation).to eq p1
                expect(c1.role).to eq 'Presenter and Author'
                expect(c1.position).to eq 1

                expect(c2.user).to eq user
                expect(c2.presentation).to eq p2
                expect(c2.role).to eq 'Author Only'
                expect(c2.position).to eq 2
              end
            end
          end
          context "when an included presentation contribution exists in the database" do
            let(:other_user) { create :user }
            let(:other_presentation) { create :presentation }
            before do
              create :presentation_contribution,
                     activity_insight_identifier: '83890556929',
                     user: other_user,
                     presentation: other_presentation,
                     role: 'Existing Role'
            end

            context "when a user that matches the contribution exists" do
              let!(:user) { create :user, activity_insight_identifier: '1649499' }
              it "creates any new contributions and updates the existing contribution" do
                expect { importer.call }.to change { PresentationContribution.count }.by 1

                p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                expect(c1.user).to eq user
                expect(c1.presentation).to eq p1
                expect(c1.role).to eq 'Presenter and Author'
                expect(c1.position).to eq 1

                expect(c2.user).to eq user
                expect(c2.presentation).to eq p2
                expect(c2.role).to eq 'Author Only'
                expect(c2.position).to eq 2
              end
            end
          end
        end
        context "when an included presentation exists in the database" do
          before do
            create :presentation,
                   activity_insight_identifier: '83890556928',
                   updated_by_user_at: updated,
                   title: 'Existing Title',
                   visible: false
          end

          context "when the existing presentation has been updated by an admin" do
            let(:updated) { Time.zone.now }
            it "creates any new presentations and does not update the existing presentation" do
              expect { importer.call }.to change { Presentation.count }.by 1

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              expect(p1.title).to eq "Existing Title"
              expect(p1.name).to be_nil
              expect(p1.organization).to be_nil
              expect(p1.location).to be_nil
              expect(p1.presentation_type).to be_nil
              expect(p1.meet_type).to be_nil
              expect(p1.scope).to be_nil
              expect(p1.attendance).to be_nil
              expect(p1.refereed).to be_nil
              expect(p1.abstract).to be_nil
              expect(p1.comment).to be_nil
              expect(p1.visible).to eq false

              expect(p2.title).to eq "Sally's PAA Presentation"
              expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
              expect(p2.organization).to be_nil
              expect(p2.location).to eq 'San Diego'
              expect(p2.presentation_type).to eq 'Papers and Presentations'
              expect(p2.meet_type).to eq 'Academic'
              expect(p2.scope).to eq 'International'
              expect(p2.attendance).to be_nil
              expect(p2.refereed).to eq 'No'
              expect(p2.abstract).to eq 'Another abstract'
              expect(p2.comment).to be_nil
              expect(p2.visible).to eq true
            end

            context "when no included presentation contributions exist in the database" do
              context "when a user that matches the contribution exists" do
                let!(:user) { create :user, activity_insight_identifier: '1649499' }

                it "creates new presentation contributions from the imported data where user IDs are present" do
                  expect { importer.call }.to change { PresentationContribution.count }.by 2

                  p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                  p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                  c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                  c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                  expect(c1.user).to eq user
                  expect(c1.presentation).to eq p1
                  expect(c1.role).to eq 'Presenter and Author'
                  expect(c1.position).to eq 1

                  expect(c2.user).to eq user
                  expect(c2.presentation).to eq p2
                  expect(c2.role).to eq 'Author Only'
                  expect(c2.position).to eq 2
                end
              end
            end
            context "when an included presentation contribution exists in the database" do
              let(:other_user) { create :user }
              let(:other_presentation) { create :presentation }
              before do
                create :presentation_contribution,
                       activity_insight_identifier: '83890556929',
                       user: other_user,
                       presentation: other_presentation,
                       role: 'Existing Role'
              end
              context "when a user that matches the contribution exists" do
                let!(:user) { create :user, activity_insight_identifier: '1649499' }

                  it "creates any new contributions and updates the existing contribution" do
                  expect { importer.call }.to change { PresentationContribution.count }.by 1

                  p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                  p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                  u = User.find_by(activity_insight_identifier: '1649499')

                  c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                  c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                  expect(c1.user).to eq u
                  expect(c1.presentation).to eq p1
                  expect(c1.role).to eq 'Presenter and Author'
                  expect(c1.position).to eq 1

                  expect(c2.user).to eq u
                  expect(c2.presentation).to eq p2
                  expect(c2.role).to eq 'Author Only'
                  expect(c2.position).to eq 2
                end
              end
            end
          end

          context "when the existing presentation has not been updated by an admin" do
            let(:updated) { nil }
            it "creates any new presentations and updates the existing presentation" do
              expect { importer.call }.to change { Presentation.count }.by 1

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              expect(p1.title).to eq "Sally's ASA Presentation"
              expect(p1.name).to eq 'Annual Meeting of the American Sociological Association'
              expect(p1.organization).to eq 'Test Organization'
              expect(p1.location).to eq 'Las Vegas, NV'
              expect(p1.presentation_type).to eq 'Roundtable Discussion'
              expect(p1.meet_type).to eq 'Academic'
              expect(p1.scope).to eq 'International'
              expect(p1.attendance).to eq 500
              expect(p1.refereed).to eq 'Yes'
              expect(p1.abstract).to eq 'An abstract'
              expect(p1.comment).to eq 'Some comments'
              expect(p1.visible).to eq false

              expect(p2.title).to eq "Sally's PAA Presentation"
              expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
              expect(p2.organization).to be_nil
              expect(p2.location).to eq 'San Diego'
              expect(p2.presentation_type).to eq 'Papers and Presentations'
              expect(p2.meet_type).to eq 'Academic'
              expect(p2.scope).to eq 'International'
              expect(p2.attendance).to be_nil
              expect(p2.refereed).to eq 'No'
              expect(p2.abstract).to eq 'Another abstract'
              expect(p2.comment).to be_nil
              expect(p2.visible).to eq true
            end

            context "when no included presentation contributions exist in the database" do
              it "creates new presentation contributions from the imported data where user IDs are present" do
                expect { importer.call }.to change { PresentationContribution.count }.by 2

                p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                u = User.find_by(activity_insight_identifier: '1649499')

                c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                expect(c1.user).to eq u
                expect(c1.presentation).to eq p1
                expect(c1.role).to eq 'Presenter and Author'
                expect(c1.position).to eq 1

                expect(c2.user).to eq u
                expect(c2.presentation).to eq p2
                expect(c2.role).to eq 'Author Only'
                expect(c2.position).to eq 2
              end
            end
            context "when an included presentation contribution exists in the database" do
              let(:other_user) { create :user }
              let(:other_presentation) { create :presentation }
              before do
                create :presentation_contribution,
                       activity_insight_identifier: '83890556929',
                       user: other_user,
                       presentation: other_presentation,
                       role: 'Existing Role'
              end
              it "creates any new contributions and updates the existing contribution" do
                expect { importer.call }.to change { PresentationContribution.count }.by 1

                p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                u = User.find_by(activity_insight_identifier: '1649499')

                c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                expect(c1.user).to eq u
                expect(c1.presentation).to eq p1
                expect(c1.role).to eq 'Presenter and Author'
                expect(c1.position).to eq 1

                expect(c2.user).to eq u
                expect(c2.presentation).to eq p2
                expect(c2.role).to eq 'Author Only'
                expect(c2.position).to eq 2
              end
            end
          end
        end

        context "when no included performances exist in the database" do
          it "creates new performances from the imported data" do
            expect { importer.call }.to change { Performance.count }.by 2

            p1 = Performance.find_by(activity_insight_id: '126500763648')
            p2 = Performance.find_by(activity_insight_id: '13745734789')

            expect(p1.title).to eq "Sally's Documentary"
            expect(p1.performance_type).to eq "Film - Documentary"
            expect(p1.sponsor).to eq "Test Sponsor"
            expect(p1.description).to eq "A description"
            expect(p1.group_name).to eq "Test Group"
            expect(p1.location).to eq "University Park, PA"
            expect(p1.delivery_type).to eq "Invitation"
            expect(p1.scope).to eq "Regional"
            expect(p1.start_on).to eq Date.new(2009, 2, 1)
            expect(p1.end_on).to eq Date.new(2009, 8, 1)
            expect(p1.visible).to eq true

            expect(p2.title).to eq "Sally's Film"
            expect(p2.performance_type).to eq "Film - Other"
            expect(p2.sponsor).to eq "Another Sponsor"
            expect(p2.description).to eq "Another description"
            expect(p2.group_name).to eq "Another Group"
            expect(p2.location).to eq "Philadelphia, PA"
            expect(p2.delivery_type).to be_nil
            expect(p2.scope).to eq "Local"
            expect(p2.start_on).to eq Date.new(2000, 2, 1)
            expect(p2.end_on).to eq Date.new(2000, 8, 1)
            expect(p2.visible).to eq true
          end

          context "when no included user performances exist in the database" do
            context "when a user that matches the contribution exists" do
              let!(:user) { create :user, activity_insight_identifier: '1649499' }
              it "creates new user performances from the imported data" do
                expect { importer.call }.to change { UserPerformance.count }.by 2

                p1 = Performance.find_by(activity_insight_id: '126500763648')
                p2 = Performance.find_by(activity_insight_id: '13745734789')

                u = User.find_by(activity_insight_identifier: '1649499')

                up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                expect(up1.user).to eq u
                expect(up1.performance).to eq p1
                expect(up1.contribution).to eq 'Director'

                expect(up2.user).to eq u
                expect(up2.performance).to eq p2
                expect(up2.contribution).to eq 'Writer'
              end
            end
          end

          context "when an included user performance exists in the database" do
            let(:other_user) { create :user }
            let(:other_performance) { create :performance }
            before do
              create :user_performance,
                     activity_insight_id: '126500763649',
                     user: other_user,
                     performance: other_performance,
                     contribution: 'Existing Contribution'
            end
            context "when a user that matches the contribution exists" do
              let!(:user) { create :user, activity_insight_identifier: '1649499' }
              it "creates any new user performances and updates the existing user performances" do
                expect { importer.call }.to change { UserPerformance.count }.by 1

                p1 = Performance.find_by(activity_insight_id: '126500763648')
                p2 = Performance.find_by(activity_insight_id: '13745734789')

                u = User.find_by(activity_insight_identifier: '1649499')

                up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                expect(up1.user).to eq u
                expect(up1.performance).to eq p1
                expect(up1.contribution).to eq 'Director'

                expect(up2.user).to eq u
                expect(up2.performance).to eq p2
                expect(up2.contribution).to eq 'Writer'
              end
            end
          end
        end

        context "when an included performance exists in the database" do
          before do
            create :performance,
                   activity_insight_id: '126500763648',
                   updated_by_user_at: updated,
                   title: 'Existing Title',
                   performance_type: nil,
                   sponsor: nil,
                   description: nil,
                   group_name: nil,
                   location: nil,
                   delivery_type: nil,
                   scope: nil,
                   start_on: nil,
                   end_on: nil,
                   visible: false
          end
          context "when the existing performance has been updated by an admin" do
            let(:updated) { Time.zone.now }
            it "creates any new performances and does not update the existing performance" do
              expect { importer.call }.to change { Performance.count }.by 1

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              expect(p1.title).to eq "Existing Title"
              expect(p1.performance_type).to be_nil
              expect(p1.sponsor).to be_nil
              expect(p1.description).to be_nil
              expect(p1.group_name).to be_nil
              expect(p1.location).to be_nil
              expect(p1.delivery_type).to be_nil
              expect(p1.scope).to be_nil
              expect(p1.start_on).to be_nil
              expect(p1.end_on).to be_nil
              expect(p1.visible).to eq false

              expect(p2.title).to eq "Sally's Film"
              expect(p2.performance_type).to eq "Film - Other"
              expect(p2.sponsor).to eq "Another Sponsor"
              expect(p2.description).to eq "Another description"
              expect(p2.group_name).to eq "Another Group"
              expect(p2.location).to eq "Philadelphia, PA"
              expect(p2.delivery_type).to be_nil
              expect(p2.scope).to eq "Local"
              expect(p2.start_on).to eq Date.new(2000, 2, 1)
              expect(p2.end_on).to eq Date.new(2000, 8, 1)
              expect(p2.visible).to eq true
            end


            context "when no included user performances exist in the database" do
              context "when a user that matches the contribution exists" do
                let!(:user) { create :user, activity_insight_identifier: '1649499' }
                it "creates new user performances from the imported data" do
                  expect { importer.call }.to change { UserPerformance.count }.by 2

                  p1 = Performance.find_by(activity_insight_id: '126500763648')
                  p2 = Performance.find_by(activity_insight_id: '13745734789')

                  u = User.find_by(activity_insight_identifier: '1649499')

                  up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                  up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                  expect(up1.user).to eq u
                  expect(up1.performance).to eq p1
                  expect(up1.contribution).to eq 'Director'

                  expect(up2.user).to eq u
                  expect(up2.performance).to eq p2
                  expect(up2.contribution).to eq 'Writer'
                end
              end
            end

            context "when an included user performance exists in the database" do
              let(:other_user) { create :user }
              let(:other_performance) { create :performance }
              before do
                create :user_performance,
                       activity_insight_id: '126500763649',
                       user: other_user,
                       performance: other_performance,
                       contribution: 'Existing Contribution'
              end
              context "when a user that matches the contribution exists" do
                let!(:user) { create :user, activity_insight_identifier: '1649499' }
                it "creates any new user performances and updates the existing user performances" do
                  expect { importer.call }.to change { UserPerformance.count }.by 1

                  p1 = Performance.find_by(activity_insight_id: '126500763648')
                  p2 = Performance.find_by(activity_insight_id: '13745734789')

                  u = User.find_by(activity_insight_identifier: '1649499')

                  up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                  up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                  expect(up1.user).to eq u
                  expect(up1.performance).to eq p1
                  expect(up1.contribution).to eq 'Director'

                  expect(up2.user).to eq u
                  expect(up2.performance).to eq p2
                  expect(up2.contribution).to eq 'Writer'
                end
              end
            end
          end

          context "when the existing performance has not been updated by an admin" do
            let(:updated) { nil }
            it "creates any new performances and updates the existing performance" do
              expect { importer.call }.to change { Performance.count }.by 1

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              expect(p1.title).to eq "Sally's Documentary"
              expect(p1.performance_type).to eq "Film - Documentary"
              expect(p1.sponsor).to eq "Test Sponsor"
              expect(p1.description).to eq "A description"
              expect(p1.group_name).to eq "Test Group"
              expect(p1.location).to eq "University Park, PA"
              expect(p1.delivery_type).to eq "Invitation"
              expect(p1.scope).to eq "Regional"
              expect(p1.start_on). to eq Date.new(2009, 2, 1)
              expect(p1.end_on).to eq Date.new(2009, 8, 1)
              expect(p1.visible).to eq false

              expect(p2.title).to eq "Sally's Film"
              expect(p2.performance_type).to eq "Film - Other"
              expect(p2.sponsor).to eq "Another Sponsor"
              expect(p2.description).to eq "Another description"
              expect(p2.group_name).to eq "Another Group"
              expect(p2.location).to eq "Philadelphia, PA"
              expect(p2.delivery_type).to be_nil
              expect(p2.scope).to eq "Local"
              expect(p2.start_on).to eq Date.new(2000, 2, 1)
              expect(p2.end_on).to eq Date.new(2000, 8, 1)
              expect(p2.visible).to eq true
            end


            context "when no included user performances exist in the database" do
              it "creates new user performances from the imported data" do
                expect { importer.call }.to change { UserPerformance.count }.by 2

                p1 = Performance.find_by(activity_insight_id: '126500763648')
                p2 = Performance.find_by(activity_insight_id: '13745734789')

                u = User.find_by(activity_insight_identifier: '1649499')

                up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                expect(up1.user).to eq u
                expect(up1.performance).to eq p1
                expect(up1.contribution).to eq 'Director'

                expect(up2.user).to eq u
                expect(up2.performance).to eq p2
                expect(up2.contribution).to eq 'Writer'
              end
            end

            context "when an included user performance exists in the database" do
              let(:other_user) { create :user }
              let(:other_performance) { create :performance }
              before do
                create :user_performance,
                       activity_insight_id: '126500763649',
                       user: other_user,
                       performance: other_performance,
                       contribution: 'Existing Contribution'
              end
              it "creates any new user performances and updates the existing user performances" do
                expect { importer.call }.to change { UserPerformance.count }.by 1

                p1 = Performance.find_by(activity_insight_id: '126500763648')
                p2 = Performance.find_by(activity_insight_id: '13745734789')

                u = User.find_by(activity_insight_identifier: '1649499')

                up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                expect(up1.user).to eq u
                expect(up1.performance).to eq p1
                expect(up1.contribution).to eq 'Director'

                expect(up2.user).to eq u
                expect(up2.performance).to eq p2
                expect(up2.contribution).to eq 'Writer'
              end
            end
          end
        end
      end



      context "when the existing user has not been updated by an admin" do
        let(:updated) { nil }

        it "creates any new users and updates the existing user" do
          expect { importer.call }.to change { User.count }.by 1

          u1 = User.find_by(webaccess_id: 'abc123')
          u2 = User.find_by(webaccess_id: 'def45')

          expect(u1.first_name).to eq 'Sally'
          expect(u1.middle_name).to be_nil
          expect(u1.last_name).to eq 'Testuser'
          expect(u1.activity_insight_identifier).to eq '1649499'
          expect(u1.penn_state_identifier).to eq '976567444'
          expect(u1.ai_building).to eq "Sally's Building"
          expect(u1.ai_room_number).to eq '123'
          expect(u1.ai_office_area_code).to eq 444
          expect(u1.ai_office_phone_1).to eq 555
          expect(u1.ai_office_phone_2).to eq 6666
          expect(u1.ai_fax_area_code).to eq 666
          expect(u1.ai_fax_1).to eq 777
          expect(u1.ai_fax_2).to eq 8888
          expect(u1.ai_website).to eq 'sociology.la.psu.edu/people/abc123'
          expect(u1.ai_bio).to eq "Sally's bio"
          expect(u1.ai_teaching_interests).to eq "Sally's teaching interests"
          expect(u1.ai_research_interests).to eq "Sally's research interests"

          expect(u2.first_name).to eq 'Bob'
          expect(u2.middle_name).to eq 'A.'
          expect(u2.last_name).to eq 'Tester'
          expect(u2.activity_insight_identifier).to eq '1949490'
          expect(u2.penn_state_identifier).to eq '9293659323'
        end

        context "when no included education history items exist in the database" do
          it "creates new education history items from the imported data" do
            expect { importer.call }.to change { EducationHistoryItem.count }.by 2

            i1 = EducationHistoryItem.find_by(activity_insight_identifier: '70766815232')
            i2 = EducationHistoryItem.find_by(activity_insight_identifier: '72346234523')
            user = User.find_by(webaccess_id: 'abc123')

            expect(i1.user).to eq user
            expect(i1.degree).to eq 'Ph D'
            expect(i1.explanation_of_other_degree).to be_nil
            expect(i1.institution).to eq 'The Pennsylvania State University'
            expect(i1.school).to eq 'Graduate School'
            expect(i1.location_of_institution).to eq 'University Park, PA'
            expect(i1.emphasis_or_major).to eq 'Sociology'
            expect(i1.supporting_areas_of_emphasis).to eq 'Demography'
            expect(i1.dissertation_or_thesis_title).to eq "Sally's Dissertation"
            expect(i1.is_highest_degree_earned).to eq 'Yes'
            expect(i1.honor_or_distinction).to be_nil
            expect(i1.description).to be_nil
            expect(i1.comments).to be_nil
            expect(i1.start_year).to eq 2006
            expect(i1.end_year).to eq 2009

            expect(i2.user).to eq user
            expect(i2.degree).to eq 'Other'
            expect(i2.explanation_of_other_degree).to eq 'Other degree'
            expect(i2.institution).to eq 'University of Pittsburgh'
            expect(i2.school).to eq 'Liberal Arts'
            expect(i2.location_of_institution).to eq 'Pittsburgh, PA'
            expect(i2.emphasis_or_major).to eq 'Psychology'
            expect(i2.supporting_areas_of_emphasis).to be_nil
            expect(i2.dissertation_or_thesis_title).to be_nil
            expect(i2.is_highest_degree_earned).to eq 'No'
            expect(i2.honor_or_distinction).to eq 'summa cum laude'
            expect(i2.description).to eq 'A description'
            expect(i2.comments).to eq 'Some comments'
            expect(i2.start_year).to eq 2000
            expect(i2.end_year).to eq 2004
          end
        end
        context "when an included education history item exists in the database" do
          let(:other_user) { create :user }
          before do
            create :education_history_item,
                   activity_insight_identifier: '70766815232',
                   user: other_user,
                   degree: 'Existing Degree',
                   explanation_of_other_degree: 'Existing Explanation',
                   institution: 'Existing Institution',
                   school: 'Existing School',
                   location_of_institution: 'Existing Location',
                   emphasis_or_major: 'Existing Major',
                   supporting_areas_of_emphasis: 'Existing Areas',
                   dissertation_or_thesis_title: 'Existing Title',
                   is_highest_degree_earned: 'No',
                   honor_or_distinction: 'Existing Honor',
                   description: 'Existing Description',
                   comments: 'Existing Comments',
                   start_year: '1990',
                   end_year: '1995'
          end

          it "creates any new items and updates the existing item" do
            expect { importer.call }.to change { EducationHistoryItem.count }.by 1

            i1 = EducationHistoryItem.find_by(activity_insight_identifier: '70766815232')
            i2 = EducationHistoryItem.find_by(activity_insight_identifier: '72346234523')
            user = User.find_by(webaccess_id: 'abc123')

            expect(i1.user).to eq user
            expect(i1.degree).to eq 'Ph D'
            expect(i1.explanation_of_other_degree).to be_nil
            expect(i1.institution).to eq 'The Pennsylvania State University'
            expect(i1.school).to eq 'Graduate School'
            expect(i1.location_of_institution).to eq 'University Park, PA'
            expect(i1.emphasis_or_major).to eq 'Sociology'
            expect(i1.supporting_areas_of_emphasis).to eq 'Demography'
            expect(i1.dissertation_or_thesis_title).to eq "Sally's Dissertation"
            expect(i1.is_highest_degree_earned).to eq 'Yes'
            expect(i1.honor_or_distinction).to be_nil
            expect(i1.description).to be_nil
            expect(i1.comments).to be_nil
            expect(i1.start_year).to eq 2006
            expect(i1.end_year).to eq 2009

            expect(i2.user).to eq user
            expect(i2.degree).to eq 'Other'
            expect(i2.explanation_of_other_degree).to eq 'Other degree'
            expect(i2.institution).to eq 'University of Pittsburgh'
            expect(i2.school).to eq 'Liberal Arts'
            expect(i2.location_of_institution).to eq 'Pittsburgh, PA'
            expect(i2.emphasis_or_major).to eq 'Psychology'
            expect(i2.supporting_areas_of_emphasis).to be_nil
            expect(i2.dissertation_or_thesis_title).to be_nil
            expect(i2.is_highest_degree_earned).to eq 'No'
            expect(i2.honor_or_distinction).to eq 'summa cum laude'
            expect(i2.description).to eq 'A description'
            expect(i2.comments).to eq 'Some comments'
            expect(i2.start_year).to eq 2000
            expect(i2.end_year).to eq 2004
          end
        end

        context "when no included presentations exist in the database" do
          it "creates new presentations from the imported data" do
            expect { importer.call }.to change { Presentation.count }.by 2

            p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
            p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

            expect(p1.title).to eq "Sally's ASA Presentation"
            expect(p1.name).to eq 'Annual Meeting of the American Sociological Association'
            expect(p1.organization).to eq 'Test Organization'
            expect(p1.location).to eq 'Las Vegas, NV'
            expect(p1.presentation_type).to eq 'Roundtable Discussion'
            expect(p1.meet_type).to eq 'Academic'
            expect(p1.scope).to eq 'International'
            expect(p1.attendance).to eq 500
            expect(p1.refereed).to eq 'Yes'
            expect(p1.abstract).to eq 'An abstract'
            expect(p1.comment).to eq 'Some comments'
            expect(p1.visible).to eq true

            expect(p2.title).to eq "Sally's PAA Presentation"
            expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
            expect(p2.organization).to be_nil
            expect(p2.location).to eq 'San Diego'
            expect(p2.presentation_type).to eq 'Papers and Presentations'
            expect(p2.meet_type).to eq 'Academic'
            expect(p2.scope).to eq 'International'
            expect(p2.attendance).to be_nil
            expect(p2.refereed).to eq 'No'
            expect(p2.abstract).to eq 'Another abstract'
            expect(p2.comment).to be_nil
            expect(p2.visible).to eq true
          end

          context "when no included presentation contributions exist in the database" do
            it "creates new presentation contributions from the imported data where user IDs are present" do
              expect { importer.call }.to change { PresentationContribution.count }.by 2

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              u = User.find_by(activity_insight_identifier: '1649499')

              c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
              c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

              expect(c1.user).to eq u
              expect(c1.presentation).to eq p1
              expect(c1.role).to eq 'Presenter and Author'
              expect(c1.position).to eq 1

              expect(c2.user).to eq u
              expect(c2.presentation).to eq p2
              expect(c2.role).to eq 'Author Only'
              expect(c2.position).to eq 2
            end
          end
          context "when an included presentation contribution exists in the database" do
            let(:other_user) { create :user }
            let(:other_presentation) { create :presentation }
            before do
              create :presentation_contribution,
                     activity_insight_identifier: '83890556929',
                     user: other_user,
                     presentation: other_presentation,
                     role: 'Existing Role'
            end
            it "creates any new contributions and updates the existing contribution" do
              expect { importer.call }.to change { PresentationContribution.count }.by 1

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              u = User.find_by(activity_insight_identifier: '1649499')

              c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
              c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

              expect(c1.user).to eq u
              expect(c1.presentation).to eq p1
              expect(c1.role).to eq 'Presenter and Author'
              expect(c1.position).to eq 1

              expect(c2.user).to eq u
              expect(c2.presentation).to eq p2
              expect(c2.role).to eq 'Author Only'
              expect(c2.position).to eq 2
            end
          end
        end
        context "when an included presentation exists in the database" do
          before do
            create :presentation,
                   activity_insight_identifier: '83890556928',
                   updated_by_user_at: updated,
                   title: 'Existing Title',
                   visible: false
          end

          context "when the existing presentation has been updated by an admin" do
            let(:updated) { Time.zone.now }
            it "creates any new presentations and does not update the existing presentation" do
              expect { importer.call }.to change { Presentation.count }.by 1

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              expect(p1.title).to eq "Existing Title"
              expect(p1.name).to be_nil
              expect(p1.organization).to be_nil
              expect(p1.location).to be_nil
              expect(p1.presentation_type).to be_nil
              expect(p1.meet_type).to be_nil
              expect(p1.scope).to be_nil
              expect(p1.attendance).to be_nil
              expect(p1.refereed).to be_nil
              expect(p1.abstract).to be_nil
              expect(p1.comment).to be_nil
              expect(p1.visible).to eq false

              expect(p2.title).to eq "Sally's PAA Presentation"
              expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
              expect(p2.organization).to be_nil
              expect(p2.location).to eq 'San Diego'
              expect(p2.presentation_type).to eq 'Papers and Presentations'
              expect(p2.meet_type).to eq 'Academic'
              expect(p2.scope).to eq 'International'
              expect(p2.attendance).to be_nil
              expect(p2.refereed).to eq 'No'
              expect(p2.abstract).to eq 'Another abstract'
              expect(p2.comment).to be_nil
              expect(p2.visible).to eq true
            end

            context "when no included presentation contributions exist in the database" do
              context "when a user that matches the contribution exists" do
                let!(:user) { create :user, activity_insight_identifier: '1649499' }

                it "creates new presentation contributions from the imported data where user IDs are present" do
                  expect { importer.call }.to change { PresentationContribution.count }.by 2

                  p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                  p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                  c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                  c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                  expect(c1.user).to eq user
                  expect(c1.presentation).to eq p1
                  expect(c1.role).to eq 'Presenter and Author'
                  expect(c1.position).to eq 1

                  expect(c2.user).to eq user
                  expect(c2.presentation).to eq p2
                  expect(c2.role).to eq 'Author Only'
                  expect(c2.position).to eq 2
                end
              end
            end
            context "when an included presentation contribution exists in the database" do
              let(:other_user) { create :user }
              let(:other_presentation) { create :presentation }
              before do
                create :presentation_contribution,
                       activity_insight_identifier: '83890556929',
                       user: other_user,
                       presentation: other_presentation,
                       role: 'Existing Role'
              end

              context "when a user that matches the contribution exists" do
                let!(:user) { create :user, activity_insight_identifier: '1649499' }

                it "creates any new contributions and updates the existing contribution" do
                  expect { importer.call }.to change { PresentationContribution.count }.by 1

                  p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                  p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                  c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                  c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                  expect(c1.user).to eq user
                  expect(c1.presentation).to eq p1
                  expect(c1.role).to eq 'Presenter and Author'
                  expect(c1.position).to eq 1

                  expect(c2.user).to eq user
                  expect(c2.presentation).to eq p2
                  expect(c2.role).to eq 'Author Only'
                  expect(c2.position).to eq 2
                end
              end
            end
          end

          context "when the existing presentation has not been updated by an admin" do
            let(:updated) { nil }
            it "creates any new presentations and updates the existing presentation" do
              expect { importer.call }.to change { Presentation.count }.by 1

              p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
              p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

              expect(p1.title).to eq "Sally's ASA Presentation"
              expect(p1.name).to eq 'Annual Meeting of the American Sociological Association'
              expect(p1.organization).to eq 'Test Organization'
              expect(p1.location).to eq 'Las Vegas, NV'
              expect(p1.presentation_type).to eq 'Roundtable Discussion'
              expect(p1.meet_type).to eq 'Academic'
              expect(p1.scope).to eq 'International'
              expect(p1.attendance).to eq 500
              expect(p1.refereed).to eq 'Yes'
              expect(p1.abstract).to eq 'An abstract'
              expect(p1.comment).to eq 'Some comments'
              expect(p1.visible).to eq false

              expect(p2.title).to eq "Sally's PAA Presentation"
              expect(p2.name).to eq 'Annual Meeting of the Population Association of America'
              expect(p2.organization).to be_nil
              expect(p2.location).to eq 'San Diego'
              expect(p2.presentation_type).to eq 'Papers and Presentations'
              expect(p2.meet_type).to eq 'Academic'
              expect(p2.scope).to eq 'International'
              expect(p2.attendance).to be_nil
              expect(p2.refereed).to eq 'No'
              expect(p2.abstract).to eq 'Another abstract'
              expect(p2.comment).to be_nil
              expect(p2.visible).to eq true
            end

            context "when no included presentation contributions exist in the database" do
              it "creates new presentation contributions from the imported data where user IDs are present" do
                expect { importer.call }.to change { PresentationContribution.count }.by 2

                p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                u = User.find_by(activity_insight_identifier: '1649499')

                c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                expect(c1.user).to eq u
                expect(c1.presentation).to eq p1
                expect(c1.role).to eq 'Presenter and Author'
                expect(c1.position).to eq 1

                expect(c2.user).to eq u
                expect(c2.presentation).to eq p2
                expect(c2.role).to eq 'Author Only'
                expect(c2.position).to eq 2
              end
            end
            context "when an included presentation contribution exists in the database" do
              let(:other_user) { create :user }
              let(:other_presentation) { create :presentation }
              before do
                create :presentation_contribution,
                       activity_insight_identifier: '83890556929',
                       user: other_user,
                       presentation: other_presentation,
                       role: 'Existing Role'
              end
              it "creates any new contributions and updates the existing contribution" do
                expect { importer.call }.to change { PresentationContribution.count }.by 1

                p1 = Presentation.find_by(activity_insight_identifier: '83890556928')
                p2 = Presentation.find_by(activity_insight_identifier: '113825011712')

                u = User.find_by(activity_insight_identifier: '1649499')

                c1 = PresentationContribution.find_by(activity_insight_identifier: '83890556929')
                c2 = PresentationContribution.find_by(activity_insight_identifier: '113825011713')

                expect(c1.user).to eq u
                expect(c1.presentation).to eq p1
                expect(c1.role).to eq 'Presenter and Author'
                expect(c1.position).to eq 1

                expect(c2.user).to eq u
                expect(c2.presentation).to eq p2
                expect(c2.role).to eq 'Author Only'
                expect(c2.position).to eq 2
              end
            end
          end
        end

        context "when no included performances exist in the database" do
          it "creates new performances from the imported data" do
            expect { importer.call }.to change { Performance.count }.by 2

            p1 = Performance.find_by(activity_insight_id: '126500763648')
            p2 = Performance.find_by(activity_insight_id: '13745734789')

            expect(p1.title).to eq "Sally's Documentary"
            expect(p1.performance_type).to eq "Film - Documentary"
            expect(p1.sponsor).to eq "Test Sponsor"
            expect(p1.description).to eq "A description"
            expect(p1.group_name).to eq "Test Group"
            expect(p1.location).to eq "University Park, PA"
            expect(p1.delivery_type).to eq "Invitation"
            expect(p1.scope).to eq "Regional"
            expect(p1.start_on).to eq Date.new(2009, 2, 1)
            expect(p1.end_on).to eq Date.new(2009, 8, 1)
            expect(p1.visible).to eq true

            expect(p2.title).to eq "Sally's Film"
            expect(p2.performance_type).to eq "Film - Other"
            expect(p2.sponsor).to eq "Another Sponsor"
            expect(p2.description).to eq "Another description"
            expect(p2.group_name).to eq "Another Group"
            expect(p2.location).to eq "Philadelphia, PA"
            expect(p2.delivery_type).to be_nil
            expect(p2.scope).to eq "Local"
            expect(p2.start_on).to eq Date.new(2000, 2, 1)
            expect(p2.end_on).to eq Date.new(2000, 8, 1)
            expect(p2.visible).to eq true
          end

          context "when no included user performances exist in the database" do
            it "creates new user performances from the imported data" do
              expect { importer.call }.to change { UserPerformance.count }.by 2

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              u = User.find_by(activity_insight_identifier: '1649499')

              up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
              up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

              expect(up1.user).to eq u
              expect(up1.performance).to eq p1
              expect(up1.contribution).to eq 'Director'

              expect(up2.user).to eq u
              expect(up2.performance).to eq p2
              expect(up2.contribution).to eq 'Writer'
            end
          end

          context "when an included user performance exists in the database" do
            let(:other_user) { create :user }
            let(:other_performance) { create :performance }
            before do
              create :user_performance,
                     activity_insight_id: '126500763649',
                     user: other_user,
                     performance: other_performance,
                     contribution: 'Existing Contribution'
            end
            it "creates any new user performances and updates the existing user performances" do
              expect { importer.call }.to change { UserPerformance.count }.by 1

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              u = User.find_by(activity_insight_identifier: '1649499')

              up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
              up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

              expect(up1.user).to eq u
              expect(up1.performance).to eq p1
              expect(up1.contribution).to eq 'Director'

              expect(up2.user).to eq u
              expect(up2.performance).to eq p2
              expect(up2.contribution).to eq 'Writer'
            end
          end
        end

        context "when an included performance exists in the database" do
          before do
            create :performance,
                   activity_insight_id: '126500763648',
                   updated_by_user_at: updated,
                   title: 'Existing Title',
                   performance_type: nil,
                   sponsor: nil,
                   description: nil,
                   group_name: nil,
                   location: nil,
                   delivery_type: nil,
                   scope: nil,
                   start_on: nil,
                   end_on: nil,
                   visible: false
          end
          context "when the existing performance has been updated by an admin" do
            let(:updated) { Time.zone.now }
            it "creates any new performances and does not update the existing performance" do
              expect { importer.call }.to change { Performance.count }.by 1

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              expect(p1.title).to eq "Existing Title"
              expect(p1.performance_type).to be_nil
              expect(p1.sponsor).to be_nil
              expect(p1.description).to be_nil
              expect(p1.group_name).to be_nil
              expect(p1.location).to be_nil
              expect(p1.delivery_type).to be_nil
              expect(p1.scope).to be_nil
              expect(p1.start_on).to be_nil
              expect(p1.end_on).to be_nil
              expect(p1.visible).to eq false

              expect(p2.title).to eq "Sally's Film"
              expect(p2.performance_type).to eq "Film - Other"
              expect(p2.sponsor).to eq "Another Sponsor"
              expect(p2.description).to eq "Another description"
              expect(p2.group_name).to eq "Another Group"
              expect(p2.location).to eq "Philadelphia, PA"
              expect(p2.delivery_type).to be_nil
              expect(p2.scope).to eq "Local"
              expect(p2.start_on).to eq Date.new(2000, 2, 1)
              expect(p2.end_on).to eq Date.new(2000, 8, 1)
              expect(p2.visible).to eq true
            end


            context "when no included user performances exist in the database" do
              context "when a user that matches the contribution exists" do
                let!(:user) { create :user, activity_insight_identifier: '1649499' }
                it "creates new user performances from the imported data" do
                  expect { importer.call }.to change { UserPerformance.count }.by 2

                  p1 = Performance.find_by(activity_insight_id: '126500763648')
                  p2 = Performance.find_by(activity_insight_id: '13745734789')

                  u = User.find_by(activity_insight_identifier: '1649499')

                  up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                  up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                  expect(up1.user).to eq u
                  expect(up1.performance).to eq p1
                  expect(up1.contribution).to eq 'Director'

                  expect(up2.user).to eq u
                  expect(up2.performance).to eq p2
                  expect(up2.contribution).to eq 'Writer'
                end
              end
            end

            context "when an included user performance exists in the database" do
              let(:other_user) { create :user }
              let(:other_performance) { create :performance }
              before do
                create :user_performance,
                       activity_insight_id: '126500763649',
                       user: other_user,
                       performance: other_performance,
                       contribution: 'Existing Contribution'
              end
              context "when a user that matches the contribution exists" do
                let!(:user) { create :user, activity_insight_identifier: '1649499' }
                it "creates any new user performances and updates the existing user performances" do
                  expect { importer.call }.to change { UserPerformance.count }.by 1

                  p1 = Performance.find_by(activity_insight_id: '126500763648')
                  p2 = Performance.find_by(activity_insight_id: '13745734789')

                  u = User.find_by(activity_insight_identifier: '1649499')

                  up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                  up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                  expect(up1.user).to eq u
                  expect(up1.performance).to eq p1
                  expect(up1.contribution).to eq 'Director'

                  expect(up2.user).to eq u
                  expect(up2.performance).to eq p2
                  expect(up2.contribution).to eq 'Writer'
                end
              end
            end
          end

          context "when the existing performance has not been updated by an admin" do
            let(:updated) { nil }
            it "creates any new performances and updates the existing performance" do
              expect { importer.call }.to change { Performance.count }.by 1

              p1 = Performance.find_by(activity_insight_id: '126500763648')
              p2 = Performance.find_by(activity_insight_id: '13745734789')

              expect(p1.title).to eq "Sally's Documentary"
              expect(p1.performance_type).to eq "Film - Documentary"
              expect(p1.sponsor).to eq "Test Sponsor"
              expect(p1.description).to eq "A description"
              expect(p1.group_name).to eq "Test Group"
              expect(p1.location).to eq "University Park, PA"
              expect(p1.delivery_type).to eq "Invitation"
              expect(p1.scope).to eq "Regional"
              expect(p1.start_on). to eq Date.new(2009, 2, 1)
              expect(p1.end_on).to eq Date.new(2009, 8, 1)
              expect(p1.visible).to eq false

              expect(p2.title).to eq "Sally's Film"
              expect(p2.performance_type).to eq "Film - Other"
              expect(p2.sponsor).to eq "Another Sponsor"
              expect(p2.description).to eq "Another description"
              expect(p2.group_name).to eq "Another Group"
              expect(p2.location).to eq "Philadelphia, PA"
              expect(p2.delivery_type).to be_nil
              expect(p2.scope).to eq "Local"
              expect(p2.start_on).to eq Date.new(2000, 2, 1)
              expect(p2.end_on).to eq Date.new(2000, 8, 1)
              expect(p2.visible).to eq true
            end


            context "when no included user performances exist in the database" do
              it "creates new user performances from the imported data" do
                expect { importer.call }.to change { UserPerformance.count }.by 2

                p1 = Performance.find_by(activity_insight_id: '126500763648')
                p2 = Performance.find_by(activity_insight_id: '13745734789')

                u = User.find_by(activity_insight_identifier: '1649499')

                up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                expect(up1.user).to eq u
                expect(up1.performance).to eq p1
                expect(up1.contribution).to eq 'Director'

                expect(up2.user).to eq u
                expect(up2.performance).to eq p2
                expect(up2.contribution).to eq 'Writer'
              end
            end

            context "when an included user performance exists in the database" do
              let(:other_user) { create :user }
              let(:other_performance) { create :performance }
              before do
                create :user_performance,
                       activity_insight_id: '126500763649',
                       user: other_user,
                       performance: other_performance,
                       contribution: 'Existing Contribution'
              end
              it "creates any new user performances and updates the existing user performances" do
                expect { importer.call }.to change { UserPerformance.count }.by 1

                p1 = Performance.find_by(activity_insight_id: '126500763648')
                p2 = Performance.find_by(activity_insight_id: '13745734789')

                u = User.find_by(activity_insight_identifier: '1649499')

                up1 = UserPerformance.find_by(activity_insight_id: '126500763649')
                up2 = UserPerformance.find_by(activity_insight_id: '126500734534')

                expect(up1.user).to eq u
                expect(up1.performance).to eq p1
                expect(up1.contribution).to eq 'Director'

                expect(up2.user).to eq u
                expect(up2.performance).to eq p2
                expect(up2.contribution).to eq 'Writer'
              end
            end
          end
        end
      end
    end
  end

  describe '#errors' do
    context "when no errors have occurred during an import" do
      before { importer.call }
      it "returns an empty array" do
        expect(importer.errors).to eq []
      end
    end
    context "when errors occur during an import" do
      let(:user) { instance_spy(User) }
      let(:error) { RuntimeError.new }
      before do
        allow(User).to receive(:find_by).with(webaccess_id: 'abc123').and_return(user)
        allow(User).to receive(:find_by).with(webaccess_id: 'def45')
        allow(user).to receive(:save!).and_raise(error)
        importer.call
      end
      it "returns an array of the errors" do
        expect(importer.errors).to eq [error]
      end
    end
  end
end
