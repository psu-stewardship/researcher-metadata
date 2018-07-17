class Publication < ApplicationRecord
  include Swagger::Blocks

  has_many :authorships
  has_many :users, through: :authorships
  has_many :imports, class_name: :PublicationImport
  has_many :contributors, -> { order position: :asc }

  validates :publication_type, :title, presence: true
  validates :publication_type, inclusion: {in: PublicationImport.publication_types }

  swagger_schema :Publication do
    property :id do
      key :type, :integer
      key :format, :int64
    end
  end
end
