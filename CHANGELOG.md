Changelog
=============

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
