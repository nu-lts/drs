class Compilation < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hydra::ModelMixins::CommonMetadata  
  include Hydra::ModelMixins::RightsMetadata
  include ActiveModel::MassAssignmentSecurity
  include Drs::MetadataAssignment
  include Drs::Find

  has_metadata name: 'DC', type: NortheasternDublinCoreDatastream
  has_metadata name: 'rightsMetadata', type: ParanoidRightsDatastream 
  has_metadata name: 'properties', type: DrsPropertiesDatastream 

  attr_accessible :title, :identifier, :depositor, :description

  has_many :entries, class_name: "NuCoreFile",  property: :has_member

  def self.users_compilations(user) 
    Compilation.find(:all).keep_if { |file| file.depositor == user.nuid } 
  end

  # Returns the pids of all objects tagged as entries 
  # in this collection.
  def entry_ids
    a = self.relationships(:has_member) 
    return a.map{ |rels| trim_to_pid(rels) } 
  end

  # Returns all NuCoreFile objects tagged as entries 
  # in this collection. 
  def entries
    a = self.relationships(:has_member) 
    return a.map { |rels| NuCoreFile.find(trim_to_pid(rels)) } 
  end

  def add_entry(value) 
    if value.instance_of?(NuCoreFile)
      add_relationship(:has_member, value) 
    elsif value.instance_of?(String) 
      object = NuCoreFile.find(value) 
      add_relationship(:has_member, object) 
    else
      raise "Add item can only take a string or an instance of a Core object" 
    end
  end

  def remove_entry(value) 
    if value.instance_of?(NuCoreFile) 
      remove_relationship(:has_member, value) 
    elsif value.instance_of?(String) 
      remove_relationship(:has_member, "info:fedora/#{value}")
    end
  end

  # Eliminate every entry ID that points to an object that no longer exists
  # Return the number of dead links removed in this fashion
  # Behavior of this method is weirdly flaky in the case where self is held in memory 
  # /while/ the NuCoreFile is deleted. 
  # If you've having problems that appear to be caused by self.relationships(:has_member) 
  # returning "info:fedora/" try reloading the object you're holding before executing this.
  def remove_dead_entries
    results = []

    self.entry_ids.each do |entry| 
      if !ActiveFedora::Base.exists?(entry) 
        results << entry 
        remove_entry(entry)
      end
    end

    self.save! 
    return results 
  end

  private

    # Takes a string of form "info:fedora/neu:abc123" 
    # and returns just the pid
    def trim_to_pid(string)
      return string.split('/').last 
    end 
end