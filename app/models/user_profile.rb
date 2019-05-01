class UserProfile
  def initialize(user)
    @user = user
  end

  delegate :name,
           :id,
           :office_location,
           :total_scopus_citations,
           :scopus_h_index,
           :pure_profile_url,
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
    user_query.publications({order_first_by: 'publication_date_desc'}).map do |pub|
      p = %{<span class="publication-title">#{pub.title}</span>}
      p += %{, <span class="journal-name">#{pub.journal_title || pub.publisher}</span>} if pub.journal_title.present? || pub.publisher.present?
      p += ", #{pub.published_on.year}" if pub.published_on.present?
      p
    end
  end

  def grants
    user_query.contracts.where(status: 'Awarded', contract_type: 'Grant').order(award_start_on: :desc).map do |grant|
      g = "#{grant.title}, #{grant.sponsor}"
      g += ", #{grant.award_start_on.strftime('%-m/%Y')} - #{grant.award_end_on.try(:strftime, '%-m/%Y')}" if grant.award_start_on.present?
      g
    end
  end

  def presentations
    user_query.presentations({}).map do |pres|
      if pres.title.present? || pres.name.present?
        p = pres.title || pres.name
        p += ", #{pres.organization}" if pres.organization.present?
        p += ", #{pres.location}" if pres.location.present?
        p
      end
    end.compact
  end

  def performances
    user.performances.order('case when start_on is null then 1 else 0 end, start_on desc').map do |perf|
      p = perf.title
      p += ", #{perf.location}" if perf.location.present?
      p += ", #{perf.start_on.strftime('%-m/%-d/%Y')}" if perf.start_on.present?
      p
    end.uniq
  end

  def master_advising_roles
    format_advising_roles(master_committee_memberships)
  end

  def phd_advising_roles
    format_advising_roles(phd_committee_memberships)
  end

  def news_stories
    user_query.news_feed_items({}).order(published_on: :desc).map do |item|
      %{<a href="#{item.url}" target="_blank">#{item.title}</a> #{item.published_on.strftime('%-m/%-d/%Y')}}
    end
  end

  def education_history
    degrees = user.education_history_items.where.not(degree: nil,
                                                     degree: "Other",
                                                     institution: nil,
                                                     emphasis_or_major: nil,
                                                     end_year: nil).order(end_year: :desc)

    degrees.map do |d|
      "#{d.degree}, #{d.emphasis_or_major} - #{d.institution} - #{d.end_year}"
    end
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

    committee_memberships.group_by { |m| m.etd }.each_value do |memberships_by_etd|
      most_significant_membership = memberships_by_etd.sort { |x, y| x <=> y }.last
      memberships.push most_significant_membership
    end

    memberships
  end

  def format_advising_roles(committee_memberships)
    most_significant_memberships(committee_memberships).map do |m|
      %{<a href="#{m.etd.url}" target="_blank">#{m.etd.title.gsub('\n', ' ')}</a> (#{m.role})}
    end
  end
end