require 'component/component_spec_helper'

describe ActivityInsightPublicationExporter do
  subject(:exporter) { ActivityInsightPublicationExporter }

  let!(:user) { FactoryBot.create :user, webaccess_id: 'abc123', activity_insight_identifier: '123456' }
  let!(:authorship1) { FactoryBot.create :authorship, user: user, publication: publication1 }
  let!(:authorship2) { FactoryBot.create :authorship, user: user, publication: publication2 }
  let!(:publication1) do
    FactoryBot.create(:publication,
                      id: 1,
                      secondary_title: 'Second Title',
                      status: 'Published',
                      journal_title: 'Journal Title',
                      volume: '1',
                      published_on: Date.parse('01/01/01'),
                      issue: '2',
                      edition: '123',
                      abstract: 'Abstract',
                      page_range: '1-2',
                      total_scopus_citations: '3',
                      authors_et_al: true,
                      user_submitted_open_access_url: 'site.org',
                      isbn: '123-123-123')
  end
  let!(:publication2) { FactoryBot.create(:publication) }
  let!(:publication3) { FactoryBot.create(:publication, exported_to_activity_insight: true) }
  let!(:ai_import) do
    FactoryBot.create(:publication_import, publication: publication2,
                       source: "Activity Insight", source_identifier: 'ai_id_1')
  end
  let!(:contributor_name1) { FactoryBot.create :contributor_name, publication: publication1 }
  let!(:contributor_name2) { FactoryBot.create :contributor_name, publication: publication2 }

  describe '#to_xml' do
    it 'generates xml' do
      exporter_object = exporter.new([], 'beta')
      expect(exporter_object.send(:to_xml, publication1)).to eq fixture('activity_insight_export.xml').read
    end
  end

  describe '#webservice_url' do
    let(:beta_url) do
      'https://betawebservices.digitalmeasures.com/login/service/v4/SchemaData/INDIVIDUAL-ACTIVITIES-University'
    end
    let(:production_url) do
      'https://webservices.digitalmeasures.com/login/service/v4/SchemaData/INDIVIDUAL-ACTIVITIES-University'
    end

    context 'when target is "beta"' do
      it 'returns beta url' do
        exporter_object = exporter.new([], 'beta')
        expect(exporter_object.send(:webservice_url)).to eq beta_url
      end
    end

    context 'when target is "production"' do
      it 'returns production url' do
        exporter_object = exporter.new([], 'production')
        expect(exporter_object.send(:webservice_url)).to eq production_url
      end
    end
  end

  describe '#export' do
    context 'when 400 code is returned from DM' do
      let(:response) do
        double 'httparty_response',
               code: 400,
               to_s: '<?xml version="1.0" encoding="UTF-8"?>

<Error>The following errors were detected:
	<Message>Unexpected EOF in prolog
 at [row,col {unknown-source}]: [1,0] Nested exception: Unexpected EOF in prolog
 at [row,col {unknown-source}]: [1,0]</Message>
</Error>'
      end

      it 'logs DM webservice responses' do
        exporter_object = exporter.new([publication1], 'beta')
        allow(HTTParty).to receive(:post).and_return response
        expect_any_instance_of(Logger).to receive(:info).with(/started at|ended at/).twice
        expect_any_instance_of(Logger).to receive(:error).with(/Unexpected EOF|lication ID: #{publication1.id}/).twice
        exporter_object.export
      end

      it 'triggers bugsnag' do
        exporter_object = exporter.new([publication1], 'beta')
        allow(HTTParty).to receive(:post).and_return response
        expect(Bugsnag).to receive(:notify).with(I18n.t('models.activity_insight_publication_exporter.bugsnag_message'))
        exporter_object.export
      end
    end

    context 'when 200 code is returned from DM' do
      let(:response) do
        double 'httparty_response',
               code: 200,
               to_s: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<Success/>\n"
      end

      it 'does not log any errors' do
        exporter_object = exporter.new([publication1], 'beta')
        allow(HTTParty).to receive(:post).and_return response
        expect_any_instance_of(Logger).to receive(:info).with(/started at|ended at/).twice
        expect_any_instance_of(Logger).not_to receive(:error)
        expect(Bugsnag).not_to receive(:notify)
        expect{ exporter_object.export }.to change{ publication1.exported_to_activity_insight }.to true
      end
    end

    context 'when publication has ai_import_identifiers' do
      it 'skips that publication' do
        exporter_object = exporter.new([publication2], 'beta')
        expect(HTTParty).not_to receive(:post)
        exporter_object.export
      end
    end

    context 'when publication.exported_to_activity_insight is true' do
      it 'skips that publication' do
        exporter_object = exporter.new([publication3], 'beta')
        expect(HTTParty).not_to receive(:post)
        exporter_object.export
      end
    end
  end
end