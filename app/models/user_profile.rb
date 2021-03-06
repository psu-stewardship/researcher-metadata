class UserProfile
  def initialize(user)
    @user = user
  end

  delegate :name,
           :id,
           :office_location,
           :office_phone_number,
           :total_scopus_citations,
           :scopus_h_index,
           :pure_profile_url,
           :orcid_identifier,
           :organization_name,
           to: :user

  def title
    user.ai_title
  end

  def email
    "#{user.webaccess_id}@psu.edu"
  end

  def personal_website
    user.ai_website
  end

  def bio
    user.ai_bio
  end

  def teaching_interests
    user.ai_teaching_interests
  end

  def research_interests
    user.ai_research_interests
  end
  
  def publications
    publication_records.where('authorships.visible_in_profile is true').map do |pub|
      AuthorshipDecorator.new(pub).label
    end
  end

  def publication_records
    user_query.publications.journal_article.order('authorships.position_in_profile ASC NULLS FIRST, published_on DESC')
  end

  def grants
    user_query.grants.order('start_date DESC NULLS LAST').map do |grant|
      g = "#{grant.name}, #{grant.agency}"
      if grant.start_date.present? && grant.end_date.present?
        g += ", #{grant.start_date.strftime('%-m/%Y')} - #{grant.end_date.try(:strftime, '%-m/%Y')}"
      end
      g
    end
  end

  def presentations
    presentation_records.where('presentation_contributions.visible_in_profile IS TRUE').map do |pres|
      p = pres.label
      p += ", #{pres.organization}" if pres.organization.present?
      p += ", #{pres.location}" if pres.location.present?
      p
    end
  end

  def presentation_records
    user_query.
      presentations.
      where("(title IS NOT NULL AND title != '') OR (name IS NOT NULL AND name != '')").
      order('presentation_contributions.position_in_profile ASC NULLS FIRST')
  end

  def performances
    performance_records.where('user_performances.visible_in_profile IS TRUE').map do |perf|
      p = perf.title
      p += ", #{perf.location}" if perf.location.present?
      p += ", #{perf.start_on.strftime('%-m/%-d/%Y')}" if perf.start_on.present?
      p
    end.uniq
  end

  def performance_records
    user.performances.
      order('user_performances.position_in_profile ASC NULLS FIRST, start_on DESC NULLS LAST')
  end

  def master_advising_roles
    format_advising_roles(master_committee_memberships)
  end

  def phd_advising_roles
    format_advising_roles(phd_committee_memberships)
  end

  def news_stories
    user_query.news_feed_items.order(published_on: :desc).map do |item|
      %{<a href="#{item.url}" target="_blank">#{item.title}</a> #{item.published_on.strftime('%-m/%-d/%Y')}}
    end
  end

  def education_history
    degrees = user.education_history_items.where.not(degree: [nil, "Other"],
                                                     institution: nil,
                                                     emphasis_or_major: nil,
                                                     end_year: nil).order(end_year: :desc)

    degrees.map do |d|
      "#{d.degree}, #{d.emphasis_or_major} - #{d.institution} - #{d.end_year}"
    end
  end

  def other_publication_records
    user_query.publications.non_journal_article.
               order('authorships.position_in_profile ASC NULLS FIRST, published_on DESC')
  end

  def other_publications
    authorships = other_publication_records.where('authorships.visible_in_profile is true')
    Hash[
      Publication.publication_types.map {
        |p| [
          p.pluralize, authorships.where('publications.publication_type = ?', p).map {
            |a| AuthorshipDecorator.new(a).label
          }
        ]
      }
    ].delete_if { |k, v| v.empty? }
  end

  def has_bio_info?
    !! (bio || research_interests || teaching_interests || education_history.any?)
  end

  private

  attr_reader :user

  def user_query
    API::V1::UserQuery.new(user)
  end

  def master_committee_memberships
    user.committee_memberships.select { |m| m.etd.submission_type == 'Master Thesis' }
  end

  def phd_committee_memberships
    user.committee_memberships.select { |m| m.etd.submission_type == 'Dissertation' }
  end

  def most_significant_memberships(committee_memberships)
    memberships = []

    committee_memberships.sort{ |m1, m2| m2.etd.year <=> m1.etd.year }.group_by { |m| m.etd }.each_value do |memberships_by_etd|
      most_significant_membership = memberships_by_etd.sort { |x, y| x <=> y }.last
      memberships.push most_significant_membership
    end

    memberships
  end

  def format_advising_roles(committee_memberships)
    most_significant_memberships(committee_memberships).map do |m|
      %{#{m.role} for #{m.etd.author_full_name} - <a href="#{m.etd.url}" target="_blank">#{m.etd.title.gsub('\n', ' ')}</a> #{m.etd.year}}
    end
  end
end
