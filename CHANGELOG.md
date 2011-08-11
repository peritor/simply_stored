Changelog
=============

0.6.8

- Lax restriction on ActiveSupport version

0.6.7

- Rebuild with Ruby 1.8

0.6.6

- Bump supported CouchPotato version

0.6.5

- Retry on connection refused errors, useful when CouchDB takes a break in excessive test runs that teardown/re-create many databases

0.6.4

- Restore Ruby 1.9.2 compatibility

0.6.3

- Compatible with CouchPotato 0.5.6

0.6.2

- Decorate conflict exceptions with information about the conflict

0.6.1

- Fix warning of dynamically created views to point to the correct called

0.6.0

- Ruby 1.9.2 compatible

- compatible with CouchPotato > 0.5 where the attributes are lazy loaded

- Depends on ActiveSupport/ActiveModel 3.x
  --> Does not longer work with Rails 2.x !

0.5.4

- Add Rake task to compact all views in a given database: 
  DATABASE=http://localhost:5984/my_db rake simply_stored:compact_design_documents

0.5.3

- Change implementation of all_documents_without_deleted view so that it can now be passed view parameters

0.5.1

- Fix nullifying soft deleted objects when they are not deleted

0.5.0

- Add support for has_and_belongs_to_many relations:

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

- Add support for .last - which is the same as first by reverse order

    User.last # => User.find(:first, :order => :desc)

- Drop support for SimpleDB

0.3.8

- Fix loading of has_many/has_one associations for inherited relations.

- Pre-populate the parent object on has_many and has_one associations so that user.posts.first.user
  doesn't reload the user.

- Add support for associations not named after the class [akm]

0.3.3

- Fix association counting bug

- Introduce :ignore option to has_many :dependent option. If :dependent is set to :ignore, 
  dependent objects will not be deleted or nullified but just ignored.

0.3.0
=============

- SimplyStored now automatically retries conflicted save operations if it is possible to resolve the conflict.
  Solving the conflict means that if updated were done one different attributes the local object will 
  refresh those attributes and try to save again. This will be tried two times by default. Afterwards the conflict
  exception will be re-raised.
  
  This feature can be controlled on the class level like this: User.auto_conflict_resolution_on_save = true | false

0.2.5
=============

- Allow to pass a custom logger to S3-attachments / RightAws

- Support :order option to has_many associations and classes, e.g:

    @user.posts(:order => :desc)
    Post.find(:all, :order => :desc)
    
  Default to the CouchDB default of ascending.
  Please update ALL design documents!


- Support :limit option to has_many and has_many :through associations, e.g:

    @user.posts(:limit => 5)

0.1.14
=============

- Add ability to delete all design documents:
    
    SimplyStored::Couch.delete_all_design_documents('http://localhost:5984/mydbname')

- Add rake tasks to delete all design documents. In your Rakefile:

    require 'simply_stored/rake'

Then you can delete all design documents in a database like this:

    DATABASE=http://localhost:5984/mydb rake simply_stored:delete_design_documents    

0.1.13
=============

- Please delete all your design documents!
- Auto-generate count-methods for has_many associations, e.g

    class Blog
      include SimplyStored::Couch
      has_many :posts
    end
    
    class Post
      include SimplyStored::Couch
      belongs_to :blog
    end
    
    blog = Blog.create
    blog.post_count
    # => 0
    
    Post.create(:blog => blog)
    blog.post_count(:force_reload => true)
    # => 1
