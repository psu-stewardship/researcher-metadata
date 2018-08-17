class Publication < ApplicationRecord
  include Swagger::Blocks

  def self.publication_types
    ["Academic Journal Article",
     "In-house Journal Article",
     "Professional Journal Article",
     "Trade Journal Article",
     "Journal Article"]
  end

  has_many :authorships, inverse_of: :publication
  has_many :users, through: :authorships
  has_many :contributors,
           -> { order position: :asc },
           dependent: :destroy,
           inverse_of: :publication
  has_many :imports, class_name: :PublicationImport

  belongs_to :duplicate_group,
             class_name: :DuplicatePublicationGroup,
             foreign_key: :duplicate_publication_group_id,
             optional: true,
             inverse_of: :publications

  validates :publication_type, :title, presence: true
  validates :publication_type, inclusion: {in: publication_types }

  accepts_nested_attributes_for :authorships, allow_destroy: true
  accepts_nested_attributes_for :contributors, allow_destroy: true

  swagger_schema :Publication do
    property :id do
      key :type, :integer
      key :format, :int64
    end
  end

  rails_admin do
    edit do
      field :title
      field :secondary_title
      field :publication_type, :enum do
        enum do
          Publication.publication_types.map { |t| [t, t] }
        end
      end
      field :journal_title
      field :publisher
      field :status
      field :volume
      field :issue
      field :edition
      field :page_range
      field :url
      field :issn
      field :doi
      field :abstract
      field :authors_et_al
      field :published_on
      field :citation_count
      field :created_at do
        read_only true
      end
      field :updated_at do
        read_only true
      end
      field :updated_by_user_at do
        read_only true
      end
      field :duplicate_group
      field :users do
        read_only true
      end
      field :authorships
      field :contributors
    end
  end

  def ai_import_identifiers
    imports.where(source: 'Activity Insight').map { |i| i.source_identifier }
  end

  def pure_import_identifiers
    imports.where(source: 'Pure').map { |i| i.source_identifier }
  end
end
