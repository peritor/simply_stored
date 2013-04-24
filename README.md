Due to the stop in development of the original creators of simply_stored, we've decided to maintain a fork with our fixes for it.


Fixes:
Fixes for the custom associations






Introduction
============

Convenience layer for CouchDB on top of CouchPotato.

SimplyStored allows you to persist your objects to CouchDB using an ActiveRecord-like syntax.

In contrast to [CouchPotato](http://github.com/langalex/couch_potato) (on top of it is build) 
it supports associations and other syntactic sugar that makes ActiveRecord so appealing. 

SimplyStored has also support for S3 attachments.

See also [RockingChair](http://github.com/jweiss/rocking_chair) on how to speed-up your unit tests 
by using an in-memory CouchDB backend.

More examples on how to work with SimplyStored can be found [here](http://github.com/jweiss/simply_stored_examples)

Installation
============

    gem install simply_stored


#### Using with Rails

Create a config/couchdb.yml:

    default: &default
      validation_framework: :active_model # optional
      split_design_documents_per_view: true # optional

    development:
      <<: *default
      database: http://localhost:5984/development_db
    test:
      <<: *default
      database: http://localhost:5984/test_db
    production:
      <<: *default
      database: <%= ENV['DB_NAME'] %>

#### Rails 2.x

In config/environment.rb:

    config.gem 'simply_stored', :source => 'http://gemcutter.org'
    config.frameworks -= [:active_record] # if you do not need ActiveRecord any more

Please note that if you use Rails 2.x, you can only use SimplyStored until version 0.5.4. SimplyStored 0.6 and above require Rails 3.x.

#### Rails 3.x

Add to your Gemfile:

    # gem 'rails' # we don't want to load activerecord so we can't require rails
    gem 'railties'
    gem 'actionpack'
    gem 'actionmailer'
    gem 'activemodel'
    gem 'simply_stored', :require => 'simply_stored/couch'

Please also see the installation info of [CouchPotato](https://github.com/langalex/couch_potato)

Usage
=============

Require SimplyStored:

    require 'simply_stored'
    CouchPotato::Config.database_name = "http://example.com:5984/name_of_the_db"
        
From now on you can define classes that use SimplyStored.

Intro
=============

SimplyStored auto-generates views for you and handles all the serialization and de-serialization stuff.

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

    
Associations
=============
    
The supported associations are: belongs_to, has_one, has_many, has_many :through, and has_and_belongs_to_many:
    
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
    
  n:m relations where the IDs are stored on one part as an array:
  
    class Server
      include SimplyStored::Couch

      property :hostname

      has_and_belongs_to_many :networks, :storing_keys => true
    end

    class Network
      include SimplyStored::Couch

      property :klass

      has_and_belongs_to_many :servers, :storing_keys => false
    end 
    
    network = Network.create(:klass => "A")
    server = Server.new(:hostname => 'www.example.com')
    network.add_server(server)
    server.network_ids # => [network.id]
    network.servers # => [server]
    server.networks # => [network]
    
  The array property holding the IDs of the other item will be used to constuct two view to lookup
  the other part. Soft deleting is only supported on the class holding the IDs.  
    
Custom Associations
=============

    class Document
      include SimplyStored::Couch

      belongs_to :creator, :class_name => "User"
      belongs_to :updater, :class_name => "User"
    end
    
    d = Document.new
    d.creator = User.first
        

Validations
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
    

S3 Attachments
=============

SimplyStored supports storing large attachments in Amazon S3. 
It uses RightAWS for the interaction with the EC2 API:

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
    
This will create an item on S3 in the specified bucket. The item will use the ID of the log object as the key and the body will be the data attribute. This way you can store big files outside of CouchDB.    
    

Soft delete
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

CouchDB - Auto resolution of conflicts on save

SimplyStored now by default retries conflicted save operations if it is possible to resolve the conflict.
Solving the conflict means that if updated were done one different attributes the local object will 
refresh those attributes and try to save again. This will be tried two times by default. Afterwards the conflict
exception will be re-raised.
  
This feature can be controlled on the class level like this: 
    User.auto_conflict_resolution_on_save = true | false
    
If auto_conflict_resolution_on_save is enabled, something like this will work:

    class Document
      include SimplyStored::Couch
      
      property :title
      property :content
    end
    
    original = Document.create(:title => 'version 1', :content => 'Hi there')
    
    other_client = Document.find(original.id)
    
    original.title = 'version 2'
    original.save!
    
    other_client.content = 'A better version'
    other_client.save!  # -> this line would fail without auto_conflict_resolution_on_save
    
    other_client.title 
    # => 'version 2'

Pagination
=============

SimplyStored supports pagination.

    class Project
      include SimplyStored::Couch
      include SimplyStored::Couch::Paginator

      property :title

      belongs_to :user
      
    end

    class User
      include SimplyStored::Couch
      include SimplyStored::Couch::Paginator

      property :name
      
      has_many :projects
      
    end

    User.build_pagination(:page => 1, :per_page => 10) # -> This will not make a database call, rather it just builds criteria for pagination

    User.build_pagination(:page =>1, :per_page => 10).all # -> This will make a call to database
    User.build_pagination(:page =>1, :per_page => 10).find_all_by_name('A name')

    user.projects(:page => 1, :per_page => 10) # -> for has_many association

    <%= will_paginate @projects %> # -> In view, it works with will_paginate to generate pagination links


License
=============

SimplyStored is licensed under the Apache 2.0 license. See LICENSE.txt

About
=============

SimplyStored was written by [Mathias Meyer](http://twitter.com/roidrage) and [Jonathan Weiss](http://twitter.com/jweiss) for [Peritor](http://www.peritor.com).

    
