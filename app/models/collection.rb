class Collection < ActiveFedora::Base
  include Hydra::Works::CollectionBehavior
  include Hydra::AccessControls::Permissions
  
  belongs_to :community, class_name: 'Community', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

  property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_searchable
  end
  property :description, predicate: ::RDF::Vocab::DC.description, multiple: false do |index|
    index.as :stored_searchable
  end
end
