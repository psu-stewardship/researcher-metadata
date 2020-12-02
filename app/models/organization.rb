class Organization < ApplicationRecord
  belongs_to :parent, class_name: :Organization, optional: true
  belongs_to :owner, class_name: :User, optional: true
  has_many :children, class_name: :Organization, foreign_key: :parent_id
  has_many :user_organization_memberships, inverse_of: :organization
  has_many :users, -> { distinct(:id) }, through: :user_organization_memberships

  validates :name, presence: true

  scope :visible, -> { where(visible: true) }

  def all_publications
    Publication.joins(users: :organizations).where(%{users.id IN (?) AND organizations.id IN (?)}, all_user_ids, descendant_ids).published_during_membership.distinct(:id)
  end

  def all_users
    User.joins(:user_organization_memberships).where(%{user_organization_memberships.organization_id IN (?)}, descendant_ids).distinct(:id)
  end

  def publications
    # A view hack for Rails Admin to get it to render some custom HTML. 
    # See the `publications` field in the Rails Admin `show` config below.
  end

  rails_admin do
    list do
      field(:id)
      field(:name)
      field(:visible)
      field(:pure_uuid)
      field(:pure_external_identifier)
      field(:organization_type)
      field(:owner)
    end

    show do
      field(:id)
      field(:name)
      field(:visible)
      field(:pure_uuid)
      field(:pure_external_identifier)
      field(:organization_type)
      field(:owner)
      field(:parent)
      field(:children)
      field(:users)
      field(:user_organization_memberships)
      field(:publications) do
        pretty_value do
          %{<a href="#{RailsAdmin.railtie_routes_url_helpers.index_publications_by_organization_path(model_name: :publication, org_id: bindings[:object].id)}">View Publications</a>}.html_safe
        end
      end
    end
  end

  private

  def descendant_ids
    ActiveRecord::Base.connection.execute(
      %{WITH RECURSIVE org_tree AS (SELECT id, name, parent_id FROM organizations WHERE id = #{id} UNION SELECT child.id, child.name, child.parent_id FROM organizations AS child JOIN org_tree AS parent ON parent.id = child.parent_id) SELECT * FROM org_tree;}
    ).to_a.map { |row| row['id'] }
  end

  def all_user_ids
    all_users.pluck(:id)
  end
end
