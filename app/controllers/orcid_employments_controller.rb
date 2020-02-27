class OrcidEmploymentsController < UserController
  before_action :authenticate!

  def create
    employment = OrcidEmployment.new(current_user.primary_organization_membership)
    employment.save!

    flash[:notice] = "The employment record was successfully added to your ORCiD profile."
    
  rescue OrcidEmployment::InvalidToken
        current_user.clear_orcid_access_token
        flash[:alert] = "Your ORCiD account is no longer linked to your metadata profile."
  rescue OrcidEmployment::FailedRequest
        flash[:alert] = "There was an error adding your employment history to your ORCiD profile."
  ensure
    redirect_to profile_bio_path
  end
end
