class Loaders::ImageReport < ActiveRecord::Base
  belongs_to :load_report
  attr_accessible :exception, :valid, :pid, :title, :collection, :iptc, :original_file
  serialize :iptc

  def self.create_success(core_file, iptc)
    x = Loaders::ImageReport.new
    x.validity             = true
    x.pid               = core_file.pid
    x.collection        = core_file.parent.pid
    x.title             = core_file.title
    x.iptc              = iptc
    x.original_file     = core_file.label
    x.save! ? x : false
  end

  def self.create_failure(exception, iptc, original_file)
    x = Loaders::ImageReport.new
    x.validity             = false
    x.exception         = exception
    x.iptc              = iptc
    x.original_file     = original_file
    x.save! ? x : false
  end
end