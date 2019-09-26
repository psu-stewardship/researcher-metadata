require 'component/component_spec_helper'

describe API::V1::UserQuery do
  let(:user) { create :user, show_all_contracts: show_all_contracts }
  let(:show_all_contracts) { true }
  let(:uq) { API::V1::UserQuery.new(user) }

  describe '#presentations' do
    context "when the given user has no presentations" do
      it "returns an empty array" do
        expect(uq.presentations({})).to eq []
      end
    end

    context "when the given user has presentations" do
      let(:invis_pres) { create :presentation, visible: false }
      let(:vis_pres) { create :presentation, visible: true }
      before { user.presentations << [invis_pres, vis_pres] }

      it "returns the user's visible presentations" do
        expect(uq.presentations({})).to eq [vis_pres]
      end
    end
  end

  describe '#performances' do
    context "when the given user has no performances" do
      it "returns an empty array" do
        expect(uq.performances({})).to eq []
      end
    end

    context "when the given user has performances" do
      let(:invis_perf) { create :performance, visible: false }
      let(:vis_perf) { create :performance, visible: true }
      before do
        create :user_performance, user: user, performance: invis_perf
        create :user_performance, user: user, performance: vis_perf
      end

      it "returns the user's visible performances" do
        expect(uq.performances({})).to eq [vis_perf]
      end
    end
  end

  describe '#publications' do
    let(:user) { create :user, show_all_publications: true }

    context "when the user can show all publications" do
      context "when the user has no publications" do
        it "returns an empty array" do
          expect(uq.publications({})).to eq []
        end
      end
      context "when the user has publications" do
        let(:invis_pub) { create :publication, visible: false }
        let(:vis_conf_pub) { create :publication, visible: true }
        let(:vis_unconf_pub) { create :publication, visible: true }
        before do
          create :authorship,
                 user: user,
                 publication: invis_pub,
                 author_number: 1,
                 confirmed: true
          create :authorship,
                 user: user,
                 publication: vis_conf_pub,
                 author_number: 1,
                 confirmed: true
          create :authorship,
                 user: user,
                 publication: vis_unconf_pub,
                 author_number: 1,
                 confirmed: false
        end

        it "returns the user's visible, confirmed publications" do
          expect(uq.publications({})).to eq [vis_conf_pub]
        end
      end
    end
    context "when the user cannot show any publications" do
      let(:user) { create :user, show_all_publications: false }

      context "when the user has no publications" do
        it "returns an empty array" do
          expect(uq.publications({})).to eq []
        end
      end
      context "when the user has publications" do
        let(:invis_pub) { create :publication, visible: false }
        let(:vis_pub) { create :publication, visible: true }
        before do
          create :authorship, user: user, publication: invis_pub, author_number: 1
          create :authorship, user: user, publication: vis_pub, author_number: 1
        end

        it "returns an empty array" do
          expect(uq.publications({})).to eq []
        end
      end
    end
  end
end
