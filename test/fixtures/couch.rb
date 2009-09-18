class User
  include SimplyStored::Couch
  validates_presence_of :title
  
  property :name
  property :title
  property :homepage
  
  view :all, :key => :created_at
  
  has_many :posts
end

class Post
  include SimplyStored::Couch
  
  belongs_to :user
  view :all, :key => :created_at
end

class Category
  include SimplyStored::Couch

  property :name
  validates_inclusion_of :name, :in => ["food", "drinks", "party"]
end