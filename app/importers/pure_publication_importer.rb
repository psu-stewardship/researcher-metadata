class PurePublicationImporter
  IMPORT_SOURCE = 'Pure'
  # This importer is initialized with a path to a directory containing one or more JSON
  # files of exported "research-outputs" data from Pure
  # (https://pennstate.pure.elsevier.com/ws/api/511/api-docs/index.html#!/research45outputs/listResearchOutputs_2)
  # The directory is assumed to only contain files of this type, and the exports should be batched
  # such that none of the files are larger than around 20 MB for efficient parsing/importing.

  attr_reader :errors

  def initialize(dirname:)
    @dirname = dirname
    @errors = []
  end

  def call
    import_files = Dir.children(dirname)
    pbar = ProgressBar.create(title: 'Importing Pure Publications', total: import_files.count) unless Rails.env.test?
    import_files.each do |filename|
      File.open(dirname.join(filename), 'r') do |file|
        MultiJson.load(file)['items'].each do |publication|
          if publication['type'].detect { |t| t['value'] == 'Article' }

            ActiveRecord::Base.transaction do
              pi = PublicationImport.find_by(source: IMPORT_SOURCE,
                                             source_identifier: publication['uuid']) ||
                PublicationImport.new(source: IMPORT_SOURCE,
                                      source_identifier: publication['uuid'])

              p = pi.publication

              pi.source_updated_at = publication['info']['modifiedDate']

              if pi.persisted?
                pi.publication.update_attributes!(pub_attrs(publication)) unless p.updated_by_user_at.present?
              else
                p = Publication.create!(pub_attrs(publication))
                pi.publication = p
              end

              pi.save!

              unless p.updated_by_user_at.present?
                p.contributors.delete_all

                authorships = publication['personAssociations'].select { |a| !a['authorCollaboration'].present? &&
                  a['personRole'].detect { |r| r['value'] == 'Author' }.present? }

                authorships.each_with_index do |a, i|
                  if a['person'].present?
                    u = User.find_by(pure_uuid: a['person']['uuid'])

                    if u # Depends on users being imported from Pure first
                      authorship = Authorship.find_by(user: u, publication: p) || Authorship.new

                      authorship.user = u if authorship.new_record?
                      authorship.publication = p if authorship.new_record?
                      authorship.author_number = i+1
                      begin
                        authorship.save!
                      rescue ActiveRecord::RecordInvalid => e
                        @errors << e
                      end
                    end
                  end

                  Contributor.create!(publication: p,
                                      first_name: a['name']['firstName'],
                                      last_name: a['name']['lastName'],
                                      position: i+1)
                end
              end
            end
          end
        end
      end
      pbar.increment unless Rails.env.test?
    end
    pbar.finish unless Rails.env.test?
    nil
  end

  private

  attr_reader :dirname

  def pub_attrs(publication)
    {
      title: publication['title'],
      secondary_title: publication['subTitle'],
      publication_type: "Academic Journal Article",
      page_range: publication['pages'],
      volume: publication['volume'],
      issue: publication['journalNumber'],
      journal_title: publication['journalAssociation']['title']['value'],
      issn: issn(publication),
      status: status(publication)['publicationStatus'][0]['value'],
      published_on: Date.new(status(publication)['publicationDate']['year'].to_i,
                             published_month(publication),
                             published_day(publication)),
      citation_count: publication['totalScopusCitations'],
      abstract: abstract(publication)
    }
  end

  def issn(publication)
    publication['journalAssociation']['issn'].present? ? publication['journalAssociation']['issn']['value'] : nil
  end

  def status(publication)
    publication['publicationStatuses'].detect { |s| s['current'] == true }
  end

  def published_month(publication)
    status(publication)['publicationDate']['month'].present? ? status(publication)['publicationDate']['month'].to_i : 1
  end

  def published_day(publication)
    status(publication)['publicationDate']['day'].present? ? status(publication)['publicationDate']['day'].to_i : 1
  end

  def abstract(publication)
    publication['abstract'].try(:first).try(:[], 'value')
  end
end
