class CustomAdmin::PublicationMergesController < RailsAdmin::ApplicationController
  def create
    group = DuplicatePublicationGroup.find(params[:duplicate_publication_group_id])

    if params[:commit] == 'Merge Selected'
      if params[:merge_target_publication_id].blank? ||
         params[:selected_publication_ids].blank? ||
          params[:selected_publication_ids] == [params[:merge_target_publication_id]]
        flash[:error] = I18n.t('admin.publication_merges.create.missing_params_error')
        redirect_to rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
        return
      end

      merge_target_pub = group.publications.find(params[:merge_target_publication_id])
      selected_pubs = group.publications.find(params[:selected_publication_ids])

      begin
        merge_target_pub.merge!(selected_pubs)
      rescue Publication::NonDuplicateMerge
        flash[:error] = I18n.t('admin.publication_merges.create.non_duplicate_merge_error')
        redirect_to rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
        return
      end

      flash[:success] = I18n.t('admin.publication_merges.create.merge_success')
    elsif params[:commit] = 'Ignore Selected'
      unless params[:selected_publication_ids] && params[:selected_publication_ids].count >= 2
        flash[:error] = I18n.t('admin.publication_merges.create.too_few_pubs_to_ignore_error')
        redirect_to rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
        return
      end
      
      selected_pubs = group.publications.find(params[:selected_publication_ids])

      ActiveRecord::Base.transaction do
        selected_pubs.each { |p| p.update_attributes!(duplicate_group: nil) }

        g = NonDuplicatePublicationGroup.new
        g.publications = selected_pubs
        g.save!
      end

      flash[:success] = I18n.t('admin.publication_merges.create.ignore_success')
    end

    redirect_to rails_admin.show_path(model_name: :duplicate_publication_group, id: group.id)
  end
end