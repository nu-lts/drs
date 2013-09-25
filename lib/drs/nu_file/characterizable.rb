# Code from Sufia mostly handles getting things to characterize via FITS correctly,
# but does leave the requisite pieces scattered across three different modules/classes.
# This encapsulates that.

module Drs
  module NuFile
    module Characterizable 
      extend ActiveSupport::Concern 
        
      # Required Sufia code 
      include Sufia::GenericFile::MimeTypes
      include Sufia::GenericFile::Characterization

      included do 
        around_save :characterize_if_changed
      end

      def pdf?
        self.class.pdf_mime_types.include? self.mime_type
      end

      def image?
        self.class.image_mime_types.include? self.mime_type
      end

      def video?
        self.class.video_mime_types.include? self.mime_type
      end

      def audio?
        self.class.audio_mime_types.include? self.mime_type
      end
    end

    private 

      def characterize_if_changed 
        content_changed = self.content.changed? 
        yield 
        Sufia.queue.push(AtomisticCharacterizationJob.new(self.pid))
      end
  end
end