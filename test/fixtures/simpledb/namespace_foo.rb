module Namespace
  class Foo < SimplyStored::Simple
    has_many :item_daddys
    belongs_to :namespace__bar
    simpledb_string :namespace__bar_id
  end
end