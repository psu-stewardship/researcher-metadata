class ETD < ApplicationRecord
  validates :title,
            :author_first_name,
            :author_last_name,
            :webaccess_id,
            :year,
            :url,
            :submission_type,
            :external_identifier,
            :access_level,
            presence: true

  has_many :committee_memberships, inverse_of: :etd
  has_many :users, through: :committee_memberships

  accepts_nested_attributes_for :committee_memberships, allow_destroy: true
end
