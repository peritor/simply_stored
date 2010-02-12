Changelog
=============

0.1.13
=============

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
