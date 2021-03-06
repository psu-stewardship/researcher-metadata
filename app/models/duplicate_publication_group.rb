class DuplicatePublicationGroup < ApplicationRecord
  has_many :publications, inverse_of: :duplicate_group

  def self.group_duplicates
    pbar = ProgressBar.create(title: 'Grouping duplicate publications',
                              total: Publication.count) unless Rails.env.test?

    Publication.find_each do |p|
      group_duplicates_of(p)

      pbar.increment unless Rails.env.test?
    end
    pbar.finish unless Rails.env.test?

    nil
  end

  def self.group_duplicates_of(publication)
    if publication.imports.count == 1 && publication.imports.detect { |i| i.source == 'Activity Insight' }
      duplicates = Publication.where(%{similarity(CONCAT(title, secondary_title), ?) >= 0.6 AND (EXTRACT(YEAR FROM published_on) = ? OR published_on IS NULL)},
                                     "#{publication.title}#{publication.secondary_title}",
                                     publication.published_on.try(:year))
                               .where.not(id: publication.non_duplicate_groups.map { |g| g.memberships.map { |m| m.publication_id } }.flatten).or(Publication.where(id: publication.id))
    else
      duplicates = Publication.where(%{similarity(CONCAT(title, secondary_title), ?) >= 0.6 AND (EXTRACT(YEAR FROM published_on) = ? OR published_on IS NULL) AND (doi = ? OR doi = '' OR doi IS NULL)},
                                     "#{publication.title}#{publication.secondary_title}",
                                     publication.published_on.try(:year),
                                     publication.doi)
                               .where.not(id: publication.non_duplicate_groups.map { |g| g.memberships.map { |m| m.publication_id } }.flatten).or(Publication.where(id: publication.id))
    end

    group_publications(duplicates)
  end

  def self.group_publications(publications)
    if publications.many?
      existing_groups = publications.select { |p| p.duplicate_group.present? }.map { |p| p.duplicate_group }
      group_to_remain = existing_groups.first
      groups_to_delete = existing_groups - [group_to_remain]
      pubs_to_regroup = groups_to_delete.map { |g| g.publications }.flatten

      ActiveRecord::Base.transaction do
        if group_to_remain
          publications.each do |p|
            p.update_attributes!(duplicate_group: group_to_remain) unless p.duplicate_group.present?
          end
          pubs_to_regroup.each do |p|
            p.update_attributes!(duplicate_group: group_to_remain)
          end
          groups_to_delete.each do |g|
            g.destroy
          end
        else
          create!(publications: publications)
        end
      end
    end
  end

  def self.auto_merge
    pbar = ProgressBar.create(title: 'Auto-merging Pure and AI groups',
                              total: count) unless Rails.env.test?
    find_each do |g|
      g.auto_merge
      pbar.increment unless Rails.env.test?
    end

    pbar.finish unless Rails.env.test?
    nil
  end

  def auto_merge
    if publication_count == 2
      pure_pub = publications.detect { |p| p.has_single_import_from_pure? }
      ai_pub = publications.detect { |p| p.has_single_import_from_ai? }

      if pure_pub && ai_pub
        ActiveRecord::Base.transaction do
          ai_pub.imports.each do |i|
            i.update_attributes!(auto_merged: true)
          end
          pure_pub.merge!([ai_pub])
          pure_pub.update_attributes!(duplicate_group: nil)
          destroy
        end
        true
      else
        false
      end
    else
      false
    end
  end

  rails_admin do
    configure :publications do
      pretty_value do
        bindings[:view].render :partial => "rails_admin/partials/duplicate_publication_groups/publications.html.erb", :locals => { :publications => value }
      end
    end

    list do
      field(:id)
      field(:first_publication_title) { label 'Title of first duplicate' }
      field(:publication_count) { label 'Number of duplicates' }
    end

    show do
      field(:id)
      field(:created_at)
      field(:publications)
    end
  end

  def publication_count
    publications.count
  end

  def first_publication_title
    publications.first.try(:title)
  end
end
