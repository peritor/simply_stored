class User
  include SimplyStored::Couch
  validates_presence_of :title
  
  property :name
  property :title
  property :homepage
  
  has_many :posts
  has_many :strict_posts
  has_many :hemorrhoids
  has_many :pains, :through => :hemorrhoids
  has_many :docs, :class_name => "Document", :foreign_key => "editor_id"
  
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
  belongs_to :network
end

class Category
  include SimplyStored::Couch

  property :name
  property :alias
  property :parent
  
  validates_inclusion_of :name, :in => ["food", "drinks", "party"], :allow_blank => true
end

class Document
  include SimplyStored::Couch
  
  belongs_to :author, :class_name => "User"
  belongs_to :editor, :class_name => "User"
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

class UniqueUserWithAView
  include SimplyStored::Couch
  
  view :by_name, :key => :email
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

class Hemorrhoid
  include SimplyStored::Couch
  
  enable_soft_delete
  
  view :by_nickname_and_size, :key => [:nickname, :size]
  
  property :nickname
  property :size
  belongs_to :user
  belongs_to :pain
  belongs_to :spot
  has_many :sub_hemorrhoids, :dependent => :destroy
  has_many :easy_sub_hemorrhoids, :dependent => :destroy
  has_many :rashs, :dependent => :nullify
  has_many :small_rashs, :dependent => :nullify
  
  before_destroy :before_destroy_callback
  after_destroy :after_destroy_callback
  
  def before_destroy_callback
  end
  
  def after_destroy_callback
  end
end

class SubHemorrhoid
  include SimplyStored::Couch
  
  enable_soft_delete
  
  belongs_to :hemorrhoid
end

class EasySubHemorrhoid
  include SimplyStored::Couch
  
  belongs_to :hemorrhoid
end

class Rash
  include SimplyStored::Couch
  
  belongs_to :hemorrhoid
end

class SmallRash
  include SimplyStored::Couch
  
  enable_soft_delete
  
  belongs_to :hemorrhoid
end

class Pain
  include SimplyStored::Couch
  
  has_many :hemorrhoids
  has_many :users, :through => :hemorrhoids
end

class Spot
  include SimplyStored::Couch
  
  has_one :hemorrhoid
end

class Master
  include SimplyStored::Couch
  
  has_many :servants, :dependent => :ignore
end

class Servant
  include SimplyStored::Couch
  
  belongs_to :master
end

class Issue
  include SimplyStored::Couch
  
  belongs_to :problem
  belongs_to :big_problem
  
  property :name
end

class Problem
  include SimplyStored::Couch
  
  has_many :issues
  has_one :issue
end

class BigProblem < Problem

end

class Server
  include SimplyStored::Couch

  property :hostname

  has_and_belongs_to_many :networks, :storing_keys => true
  has_and_belongs_to_many :subnets, :storing_keys => true
  has_and_belongs_to_many :ips, :storing_keys => false
end

class Network
  include SimplyStored::Couch

  property :klass

  has_and_belongs_to_many :servers, :storing_keys => false
  has_and_belongs_to_many :routers, :storing_keys => false
end

class Subnet < Network
  has_and_belongs_to_many :servers, :storing_keys => false
end

class Ip
  include SimplyStored::Couch

  has_and_belongs_to_many :servers, :storing_keys => true
end

class Router
  include SimplyStored::Couch
  enable_soft_delete

  property :hostname

  has_and_belongs_to_many :networks, :storing_keys => true
end

class Book
  include SimplyStored::Couch

  property :title

  has_and_belongs_to_many :authors, :storing_keys => true
end

class Author
  include SimplyStored::Couch
  enable_soft_delete

  property :name

  has_and_belongs_to_many :books, :storing_keys => false
end

class PaginatedUser
  include SimplyStored::Couch
  include SimplyStored::Couch::Paginator

  has_many :paginated_articles

  property :name
end

class PaginatedArticle
  include SimplyStored::Couch
  include SimplyStored::Couch::Paginator

  belongs_to :paginated_user

  property :title
end