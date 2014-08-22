include Drs::ThumbnailCreation

class DerivativeCreator

  attr_accessor :core, :master

  def initialize(master_pid)
    @master = ActiveFedora::Base.find(master_pid, cast: true)
    @core = NuCoreFile.find(@master.core_record.pid)
  end

  def generate_derivatives

    blob = nil

    if master.instance_of? MswordFile
      pdf = create_pdf_file
      pdf.transform_datastream(:content, content: { datastream: 'content', size: '1000x1000>' })
      blob = pdf.content.content
    else
      blob = self.master.content.content
    end

    create_all_thumbnail_sizes(blob, @core.thumbnail_list)
  end

  private

    def create_all_thumbnail_sizes(blob, thumbnail_list)
      # TODO: this needs to pass the pid instead...
      thumb = find_or_create_thumbnail

      create_scaled_progressive_jpeg(thumb, blob, {height: 85, width: 85}, 'thumbnail_1')
      create_scaled_progressive_jpeg(thumb, blob, {height: 170, width: 170}, 'thumbnail_2')
      create_scaled_progressive_jpeg(thumb, blob, {height: 340, width: 340}, 'thumbnail_3')
      create_scaled_progressive_jpeg(thumb, blob, {width: 500}, 'thumbnail_4')
      create_scaled_progressive_jpeg(thumb, blob, {width: 1000}, 'thumbnail_5')

      for i in 1..5 do
        @core.thumbnail_list << "/downloads/#{self.core.thumbnail.pid}?datastream_id=thumbnail_#{i}"
      end

      @core.save!
    end

    # Create or update a PDF file.
    # Should only be called when Msword Files are uploaded.
    def create_pdf_file
      title = "#{core.title} pdf"
      desc = "PDF for #{core.pid}"

      if self.core.content_objects.find { |e| e.instance_of? PdfFile }
        original = self.core.content_objects.find { |e| e.instance_of? PdfFile }
        pdf = update_or_create_with_metadata(title, desc, PdfFile, original)
      else
        pdf = update_or_create_with_metadata(title, desc, PdfFile)
      end

      master.transform_datastream(:content, { to_pdf: { format: 'pdf', datastream: 'pdf'} }, processor: 'document')
      pdf.add_file(master.pdf.content, 'content', "#{master.content.label.split('.').first}.pdf")
      pdf.original_filename = "#{master.content.label.split('.').first}.pdf"
      pdf.save! ? pdf : false
    end

    def update_or_create_with_metadata(title, desc, klass, object = nil)
      if object.nil?
        object = klass.new(pid: Drs::Noid.namespaceize(Drs::IdService.mint))
      end

      object.title                  = title
      object.identifier             = object.pid
      object.description            = desc
      object.keywords               = core.keywords.flatten unless core.keywords.nil?
      object.depositor              = core.depositor
      object.proxy_uploader         = core.proxy_uploader
      object.core_record            = core
      object.rightsMetadata.content = master.rightsMetadata.content
      object.save! ? object : false
    end

    def find_or_create_thumbnail
      title = "#{core.title} thumbnails"
      desc = "Thumbnails for #{core.pid}"

      if self.core.thumbnail
        update_or_create_with_metadata(title, desc, ImageThumbnailFile, self.core.thumbnail)
      else
        update_or_create_with_metadata(title, desc, ImageThumbnailFile)
      end
    end
end
