class User
  include SimplyStored::Couch
  validates_presence_of :title
  
  property :name
  property :title
  property :homepage
  
  has_many :posts
end

class Post
  include SimplyStored::Couch
  
  belongs_to :user
end

class Category
  include SimplyStored::Couch

  property :name
  property :alias
  property :parent
  
  validates_inclusion_of :name, :in => ["food", "drinks", "party"], :allow_blank => true
end

class Tag
  include SimplyStored::Couch
  
  belongs_to :category
  property :name
end

class Instance
  include SimplyStored::Couch
  has_one :identity
end

class Identity
  include SimplyStored::Couch
  belongs_to :instance
  belongs_to :magazine
end

class Magazine
  include SimplyStored::Couch
  has_one :identity, :dependent => :destroy
end