class Item < SimplyStored::Simple
  simpledb_string :foo_attribute, :item_daddy_id
  simpledb_array :bar_attribute_array
  simpledb_timestamp :updated_at, :created_at
  simpledb_integer :integer_field
  
  require_inclusion_of :foo_attribute, ['a', 'b', 'c']
  require_inclusion_of :bar_attribute_array, ['goog', 'boob']
  
  belongs_to :item_daddy
end
