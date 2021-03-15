class ProfilesController < ProfileManagementController
  skip_before_action :authenticate!, only: [:show]

  def show
    @profile = UserProfile.new(User.find_by!(webaccess_id: params[:webaccess_id]))
  end

  def edit_publications
    authorships = UserProfile.new(current_user).publication_records.
      map { |p| p.authorships.find_by(user: current_user) }
    @authorships = authorships.map { |a| AuthorshipDecorator.new(a, view_context) }
    @waivers = current_user.external_publication_waivers
  end

  def edit_presentations
    @presentation_contributions = UserProfile.new(current_user).presentation_records.
      map { |p| p.presentation_contributions.find_by(user: current_user) }
  end

  def edit_performances
    @user_performances = UserProfile.new(current_user).performance_records.
      map { |p| p.user_performances.find_by(user: current_user) }
  end

  def edit_other_publications
    authorships = UserProfile.new(current_user).other_publication_records.
      map { |p| p.authorships.find_by(user: current_user) }
    @user_other_publications = authorships.map { |a| AuthorshipDecorator.new(a, view_context) }
  end

  def bio
    @user = current_user
    @memberships = current_user.user_organization_memberships
  end

  helper_method :profile_for_current_user?

  private

  def profile_for_current_user?
    current_user && current_user.webaccess_id == params[:webaccess_id]
  end
end