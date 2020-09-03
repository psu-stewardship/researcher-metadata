class PureUserImporter
  def initialize(filename:)
    @filename = filename
    @errors = []
  end

  def call
    File.open(filename, 'r') do |file|
      json = MultiJson.load(file)
      pbar = ProgressBar.create(title: 'Importing Pure users', total: json['items'].count) unless Rails.env.test?

      json['items'].each do |user|
        if user['externalId'].present?
          pbar.increment unless Rails.env.test?
          first_and_middle_name = user['name']['firstName']
          first_name = first_and_middle_name.split(' ')[0].try(:strip)
          middle_name = first_and_middle_name.split(' ')[1].try(:strip)
          webaccess_id = user['externalId'].downcase

          u = User.find_by(webaccess_id: webaccess_id) || User.new

          # Create the user with Pure data if we don't have a record at all, and update
          # it with new Pure data if we've never imported the user from Activity Insight
          # and it's never been updated manually. We assume that Activity Insight
          # and manual entry are both better sources of user data than Pure.
          u.scopus_h_index = user['scopusHIndex']
          u.pure_uuid = user['uuid']

          if u.new_record? || (u.activity_insight_identifier.blank? && u.updated_by_user_at.blank?)
            u.first_name = first_name
            u.middle_name = middle_name
            u.last_name = user['name']['lastName']
            u.webaccess_id = webaccess_id if u.new_record?
          end

          u.save!

          if user['staffOrganisationAssociations']
            user['staffOrganisationAssociations'].each do |a|
              o_uuid = a['organisationalUnit']['uuid']

              o = o_uuid ? Organization.find_by(pure_uuid: o_uuid) : nil

              if o
                m = UserOrganizationMembership.find_by(pure_identifier: a['pureId']) || UserOrganizationMembership.new

                m.pure_identifier = a['pureId'] if m.new_record?
                m.organization = o
                m.user = u
                m.imported_from_pure = true
                m.primary = a['isPrimaryAssociation']
                m.position_title = position_title(a)
                m.started_on = a['period']['startDate']
                m.ended_on = a['period']['endDate']
                m.save!
              end
            end
          end
        end
      end
      pbar.finish unless Rails.env.test?
    end
    nil
  end

  private

  attr_reader :filename

  def position_title(association)
    association['jobDescription'] && association['jobDescription']['text'].detect { |text| text['locale'] == 'en_US' }['value']
  end
end
