class OrcidAccessTokensController < UserController
  before_action :authenticate!
  layout 'manage_profile'

  def new
    if current_user.orcid_access_token.present?
      flash[:notice] = I18n.t('profile.orcid_access_tokens.new.already_linked')
      redirect_to profile_bio_path
    else
      redirect_to "https://#{'sandbox.' unless Rails.env.production?}orcid.org/oauth/authorize?client_id=#{Rails.configuration.x.orcid['client_id']}&response_type=code&scope=/read-limited%20/activities/update%20/person/update&redirect_uri=#{URI::encode(orcid_access_token_url)}"
    end
  end

  def create
    if params[:error] == 'access_denied'
      flash.now[:alert] = I18n.t('profile.orcid_access_tokens.create.authorization_denied')
      render :create
    else
      response = oauth_client.create_token(params[:code])

      if response.code == 200
        current_user.update_attributes!(orcid_access_token: response['access_token'],
                                        orcid_refresh_token: response['refresh_token'],
                                        orcid_access_token_expires_in: response['expires_in'],
                                        orcid_access_token_scope: response['scope'],
                                        authenticated_orcid_identifier: response['orcid'])
        flash[:notice] = I18n.t('profile.orcid_access_tokens.create.success')
        redirect_to profile_bio_path
      else
        flash[:alert] = I18n.t('profile.orcid_access_tokens.create.error')
        redirect_to profile_bio_path
      end
    end
  end

  private

  def oauth_client
    @oauth_client ||= OrcidOauthClient.new
  end
end
