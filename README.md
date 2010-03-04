Convenience layer for CouchDB and SimpleDB. Requires CouchPotato and RightAWS library respectively.

SimplyStored allows you to persist your objects to CouchDB (or SimpleDB) using an ActiveRecord-like syntax.

In contrast to [CouchPotato](http://github.com/langalex/couch_potato) (on top of it is build) 
it supports associations and other syntactic sugar that makes ActiveRecord so appealing. 

Both backends have also support for S3 attachments.

See also [RockingChair](http://github.com/jweiss/rocking_chair) on how to speed-up your unit tests 
by using an in-memory CouchDB backend.

Installation
============

    gem install simply_stored

Usage
=============

Require the SimplyStored and decide with backend you want (CouchDB or SimpleDB).

    require 'simply_stored/couch'
    CouchPotato::Config.database_name = "http://example.com:5984/name_of_the_db"
    
or

    require 'simply_stored/simpledb'
    SimplyStored::Simple.aws_access_key = 'foo'
    SimplyStored::Simple.aws_secret_access_key = 'bar'
    RightAws::ActiveSdb.establish_connection(SimplyStored::Simple.aws_access_key, SimplyStored::Simple.aws_secret_access_key, :protocol => 'https')
    
From now on you can define classes that use SimplyStored.

CouchDB - Intro
=============

The CouchDB backend is better supported and has more features. It auto-generates views for you and handles 
all the serialization and de-serialization stuff.

    class User
      include SimplyStored::Couch
      
      property :login
      property :age
      property :accepted_terms_of_service, :type => :boolean
      property :last_login, :type => Time
    end

    user = User.new(:login => 'Bert', :age => 12, :accepted_terms_of_service => true, :last_login = Time.now)
    user.save
    
    User.find_by_age(12).login
    # => 'Bert'
    
    User.all
    # => [user]
    
    class Post
      include SimplyStored::Couch
      
      property :title
      property :body
      
      belongs_to :user
    end
    
    class User
      has_many :posts
    end
    
    post = Post.create(:title => 'My first post', :body => 'SimplyStored is so nice!', :user => user)
    
    user.posts
    # => [post]
    
    Post.find_all_by_title_and_user_id('My first post', user.id).first.body
    # => 'SimplyStored is so nice!'
    
    post.destroy
    
    user.posts(:force_reload => true)
    # => []

    
CouchDB - Associations
=============
    
The supported associations are: belongs_to, has_one, has_many, and has_many :through
    
    class Post
      include SimplyStored::Couch
      
      property :title
      property :body
      
      has_many :posts, :dependent => :destroy
      has_many :users, :through => :posts
      belongs_to :user
    end
    
    class Comment
      include SimplyStored::Couch
      
      property :body
      
      belongs_to :post
      belongs_to :user
    end
    
    post = Post.create(:title => 'Look ma!', :body => 'I can have comments')
    
    mike = User.create(:login => 'mike')
    mikes_comment = Comment.create(:user => mike, :post => post, :body => 'Wow, comments are nice')
    
    john = User.create(:login => 'john')
    johns_comment = Comment.create(:user => john, :post => post, :body => 'They are indeed')
    
    post.comments
    # => [mikes_comment, johns_comment]
    
    post.comments(:order => :desc)
    # => [johns_comment, mikes_comment]
    
    post.comments(:limit => 1)
    # => [mikes_comment]
    
    post.comment_count
    # => 2
    
    post.users
    # => [mike, john]

    post.user_count
    # => 2
    

CouchDB - Validations
=============

Further, you can have validations (using the validatable gem)

    class Project
      include SimplyStored::Couch
    
      property :title
      property :budget
      property :deadline, :type => Time
      property :priority
      
      validates_presence_of :budget
      validates_uniqueness_of :priority
      validates_format_of :title, :with => /\A[a-z0-9\-']+\Z/, :allow_blank => true
      validates_inclusion_of :priority, :in => [0,1,2,3,4,5]
      
    end
    
    project = Project.new
    project.save
    # => false
    
    project.errors
    # => #<Validatable::Errors:0x102592740 @errors={:budget=>["can't be empty"], :priority=>["must be one or more of 0, 1, 2, 3, 4, 5"]}
    
    project.save!
    # => raises CouchPotato::Database::ValidationsFailedError: #<CouchPotato::Database::ValidationsFailedError:0x102571130>
    

CouchDB - S3 Attachments
=============

Both the CouchDB backend and the SimpleDB backend have support for S3 attachments:

    class Log
      include SimplyStored::Couch
      has_s3_attachment :data, :bucket => 'the-bucket-name',
                               :access_key => 'my-AWS-key-id',
                               :secret_access_key => 'psst!-secret',
                               :location => :eu,
                               :after_delete => :delete,
                               :logger => Logger.new('/dev/null')
      
    end
    
    log = Log.new
    log.data = File.read('/var/log/messages')
    log.save
    # => true
    
    log.data_size
    # => 11238132
    
This will create an item on S3 in the specified bucket. The item will use the ID of the log object as the key and the body will be the data attribute. This way you can store big files outside of CouchDB or SimpleDB.    
    

CouchDB - Soft delete
=============
    
SimplyStored also has support for "soft deleting" - much like acts_as_paranoid. Items will then not be deleted but only marked as deleted. This way you can recover them later.

    class Document
      include SimplyStored::Couch
      
      property :title
      enable_soft_delete # will use :deleted_at attribute by default
    end
    
    doc = Document.create(:title => 'secret project info')
    Document.find_all_by_title('secret project info')
    # => [doc]
    
    doc.destroy
    
    Document.find_all_by_title('secret project info')
    # => []
    
    Document.find_all_by_title('secret project info', :with_deleted => true)
    # => [doc]


License
=============

SimplyStored is licensed under the OpenBSD / two-clause BSD license, modeled after the ISC license. See LICENSE.txt

About
=============

SimplyStored was written by [Mathias Meyer](http://twitter.com/roidrage) and [Jonathan Weiss](http://twitter.com/jweiss) for [Peritor](http://www.peritor.com).

    