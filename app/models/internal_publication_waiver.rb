class InternalPublicationWaiver < ApplicationRecord
  belongs_to :authorship, inverse_of: :waiver
  has_one :user, through: :authorship
  has_one :publication, through: :authorship

  delegate :title, :abstract, :doi, :published_by, to: :authorship, prefix: false

  rails_admin do
    list do
      field(:id)
      field(:publication) do
        pretty_value { value.title }
      end
      field(:user) do
        pretty_value { value.name }
      end
    end

    show do
      field(:id)
      field(:publication) do
        pretty_value { value.title }
      end
      field(:user) do
        pretty_value { value.name }
      end
      field(:reason_for_waiver)
      field(:authorship)
    end
  end
end
