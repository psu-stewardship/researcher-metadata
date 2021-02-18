class Publisher < ApplicationRecord
  has_many :journals, inverse_of: :publisher
  has_many :publications, through: :journals

  scope :ordered_by_publication_count, -> { unscope(:order).left_outer_joins(:publications).group('publishers.id').order(Arel.sql('COUNT(publications.id) DESC')) }
  scope :ordered_by_name, -> { order(:name) }

  def publication_count
    publications.count
  end

  rails_admin do
    list do
      scopes [:ordered_by_name, :ordered_by_publication_count]
      field(:id)
      field(:name)
      field(:publication_count)
    end

    show do
      field(:name)
      field(:pure_uuid)
      field(:journals)
      field(:publication_count)
      field(:publications)
    end

    export do
      configure :publication_count do
        show
      end
    end
  end
end
