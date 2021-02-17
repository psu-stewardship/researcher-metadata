class ContributorName < ApplicationRecord
  belongs_to :publication, inverse_of: :contributor_names

  validates :publication, :position, presence: true
  validate :at_least_one_name_present

  def name
    full_name = first_name.to_s
    full_name += ' ' if first_name.present? && middle_name.present?
    full_name += middle_name.to_s if middle_name.present?
    full_name += ' ' if middle_name.present? && last_name.present? || first_name.present? && last_name.present?
    full_name += last_name.to_s if last_name.present?
    full_name
  end

  private

  def at_least_one_name_present
    unless first_name.present? || middle_name.present? || last_name.present?
      errors[:base] << "At least one name must be present."
    end
  end
end