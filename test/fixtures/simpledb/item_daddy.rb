class ItemDaddy < SimplyStored::Simple
  simpledb_string :name, 'namespace__foo_id'
  require_attributes :name
  
  has_one :item
  has_many :items
  
end