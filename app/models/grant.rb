class Grant < ApplicationRecord
  validates :agency_name, presence: true

  has_many :research_funds
  has_many :publications, through: :research_funds

  def name
    identifier
  end

  rails_admin do
    list do
      field(:id)
      field(:agency_name)
      field(:identifier)
      field(:created_at)
      field(:updated_at)
    end

    show do
      field(:id)
      field(:agency_name)
      field(:identifier)
      field(:publications)
      field(:created_at)
      field(:updated_at)
    end
  end
end