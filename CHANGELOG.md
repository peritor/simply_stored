Changelog
=============

- Support :order option to has_many associations and classes, e.g:

    @user.posts(:order => :desc)
    Post.find(:all, :order => :desc)
    
  Default to the CouchDB default of ascending.


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
