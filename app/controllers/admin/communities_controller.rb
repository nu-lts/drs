class Admin::CommunitiesController < AdminController
  include Cerberus::TempFileStorage

  # Loads @community
  load_resource

  def index
    community_model = ActiveFedora::SolrService.escape_uri_for_query "info:fedora/afmodel:Community"
    query_result = ActiveFedora::SolrService.query("has_model_ssim:\"#{community_model}\"", :rows => 999)
    @communities = query_result.map { |x| SolrDocument.new(x) }
    @page_title = "Administer Communities"
  end

  def new
    @page_title = "Create New Community"
  end

  def create
    @community = Community.new(params[:community].merge(pid: mint_unique_pid))
    @community.depositor = current_user.nuid
    @community.identifier = @community.pid

    if get_parent_mass_permissions == 'private' && @community.mass_permissions == 'public'
      flash.now[:error] = "Parent community is set to private, can't have public child."
      render :action => 'new' and return
    end

    if @community.save!
      update_theses_and_thumbnail
      flash[:info] = "Community created successfully."
      redirect_to admin_communities_path and return
    else
      flash.now[:error] = "Something went wrong"
      redirect_to admin_communities_path and return
    end
  end

  def edit
    @page_title = "Administer #{@community.title}"
  end

  def update

    if get_parent_mass_permissions == 'private' && @community.mass_permissions == 'public'
      flash.now[:error] = "Parent community is set to private, can't have public child."
      render :action => 'new' and return
    end

    update_theses_and_thumbnail

    if @community.update_attributes(params[:community])
      flash[:notice] =  "Community #{@community.title} was updated successfully."
      redirect_to admin_communities_path
    else
      flash[:notice] = "Community #{@community.title} failed to update."
      redirect_to admin_communities_path
    end
  end

  def destroy
    title = @community.title

    if @community.destroy
      flash[:notice] = "Community #{title} destroyed"
      redirect_to admin_communities_path
    else
      flash[:error] = "Failed to destroy community"
      redirect_to admin_communities_path
    end
  end

  private

    def get_parent_mass_permissions
      if params[:community][:parent]
        return Community.find(params[:community][:parent]).mass_permissions
      elsif @community.parent
        return @community.parent.mass_permissions
      else # Need this case to handle community @ neu:1
        return 'public'
      end
    end

    def update_theses_and_thumbnail
      if params[:thumbnail]
        file = params[:thumbnail]
        new_path = move_file_to_tmp(file)
        Cerberus::Application::Queue.push(SetThumbnailCreationJob.new(@community.pid, new_path))
      end

      if params[:theses] == '1' && !@community.theses
        etdDesc = I18n.t "drs.etd_description.default"
        Collection.create(title: "Theses and Dissertations",
                            description: "#{etdDesc} #{@community.title}",
                            depositor: current_user.nuid,
                            smart_collection_type: 'Theses and Dissertations',
                            mass_permissions: @community.mass_permissions,
                            parent: @community)
      end
    end
end
