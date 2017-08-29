class SentinelsController < ApplicationController
  def new
    @sentinel = Sentinel.new
    @content_list = [["Audio Master", "audio_master"],
                    ["Audio", "audio"],
                    ["Image Master", "image_master"],
                    ["Image Large", "image_large"],
                    ["Image Medium", "image_medium"],
                    ["Image Small", "image_small"],
                    ["Powerpoint", "mspowerpoint"],
                    ["Excel", "msexcel"],
                    ["Word ", "msword"],
                    ["Pdf", "pdf"],
                    ["Text", "text"],
                    ["Video Master", "video_master"],
                    ["Video", "video"],
                    ["Zip", "zip"]]

    @set = ActiveFedora::Base.find(params[:parent], cast: true)

    if @set.class == Collection
      @collection = true
      flash[:alert] = "Core file mass permissions must be set for a collection sentinel. If a content object model is disabled, content objects uploaded to this collection with that file type will be assigned the same permissions set for the core file."
    else
      flash[:alert] = "Enable models and select the correct permissions for the core files and content objects in this Set that you would like to update. If a content object model is disabled, content objects in this Set with that file type will not be updated."
    end
  end

  def create
    sentinel = Sentinel.new(params["sentinel"])
    sentinel.save!

    doc = SolrDocument.new ActiveFedora::SolrService.query("id:\"#{sentinel.set_pid}\"").first

    # Add user email
    sentinel.email = current_user.email
    sentinel.save!

    # Collection sentinels are not retroactive
    if doc.klass == "Compilation"
      Cerberus::Application::Queue.push(SentinelJob.new(sentinel.id))

      flash[:notice] = "A new sentinel has been created and the Set's files are being updated."
    elsif doc.klass == "Collection"
      # Designate as permanent
      sentinel.permanent = true
      sentinel.save!

      flash[:notice] = "A new sentinel has been created and will be used to assign permissions for all future files uploaded to this collection using the XML, spreadsheet, multipage, or IPTC loaders."
    end

    redirect_to(polymorphic_path(ActiveFedora::Base.find(sentinel.set_pid, cast: true))) and return
  end

  def edit
    @content_list = [["Audio Master", "audio_master"],
                    ["Audio", "audio"],
                    ["Image Master", "image_master"],
                    ["Image Large", "image_large"],
                    ["Image Medium", "image_medium"],
                    ["Image Small", "image_small"],
                    ["Powerpoint", "mspowerpoint"],
                    ["Excel", "msexcel"],
                    ["Word ", "msword"],
                    ["Pdf", "pdf"],
                    ["Text", "text"],
                    ["Video Master", "video_master"],
                    ["Video", "video"],
                    ["Zip", "zip"]]

    @sentinel = Sentinel.find(params[:id])
    @set = ActiveFedora::Base.find(@sentinel.set_pid, cast: true)

    if @set.class == Collection
      @collection = true
    end
  end

  def update
    # Set disabled models to {}
    model_list = Sentinel.column_names - ["id", "created_at", "updated_at", "set_pid", "pid_list", "permanent", "email", "core_file"]
    model_list.reject! { |m| params["sentinel"].include? m }

    sentinel = Sentinel.find(params[:id])
    sentinel.update_attributes(params[:sentinel].merge(Hash[model_list.map{ |m| [m,{}] }]))
    flash[:notice] = "The sentinel was successfully edited."
    redirect_to(polymorphic_path(ActiveFedora::Base.find(sentinel.set_pid, cast: true))) and return
  end
end