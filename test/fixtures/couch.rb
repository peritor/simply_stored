class User
  include SimplyStored::Couch
  validates_presence_of :title
  
  property :name
  property :title
  property :homepage
  
  has_many :posts
  has_many :strict_posts
  
  view :by_name_and_created_at, :key => [:name, :created_at]
end

class Post
  include SimplyStored::Couch
  
  belongs_to :user
end

class StrictPost
  include SimplyStored::Couch
  
  belongs_to :user
  
  validates_presence_of :user
end

class Comment
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

class CouchLogItem
  include SimplyStored::Couch
  has_s3_attachment :log_data, :bucket => "bucket-for-monsieur", :access_key => 'abcdef', :secret_access_key => 'secret!'
end

class UniqueUser
  include SimplyStored::Couch
  
  property :name
  validates_uniqueness_of :name
end

class CountMe
  include SimplyStored::Couch
  
  property :title
end

class DontCountMe
  include SimplyStored::Couch
  
  property :title
end

class Journal
  include SimplyStored::Couch
  
  has_many :memberships, :dependent => :destroy
  has_many :readers, :through => :memberships, :dependent => :destroy
  property :foo
end

class Reader
  include SimplyStored::Couch
  
  has_many :memberships, :dependent => :destroy
  has_many :journals, :through => :memberships
end

class Membership
  include SimplyStored::Couch
  
  belongs_to :reader
  belongs_to :journal
end