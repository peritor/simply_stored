require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/couch')

class HasAndBelongsToManyTest < Test::Unit::TestCase
  context "has_and_belongs_to_many" do
    setup do
      CouchPotato::Config.database_name = 'simply_stored_test'
      recreate_db
    end

    context "with has_and_belongs_to_many" do
      should "create a fetch method for the associated objects" do
        server = Server.new
        assert server.respond_to?(:networks)

        network = Network.new
        assert network.respond_to?(:servers)
      end

       should "raise an error if another property with the same name already exists" do
        assert_raise(RuntimeError) do
          class ::DoubleHasAdnBelongsToManyServer
            include SimplyStored::Couch
            property :other_users
            has_and_belongs_to_many :other_users
          end
        end
      end

      should "fetch the associated objects" do
        network = Network.create(:klass => "A")
        3.times {
          server = Server.new
          server.network_ids = [network.id]
          server.save!
        }
        assert_equal 3, network.servers.size
      end

      should "fetch the associated objects from the other side of the relation" do
        network = Network.create(:klass => "A")
        3.times {
          server = Server.new
          server.network_ids = [network.id]
          server.save!
        }
        assert_equal 1, Server.first.networks.size
      end

      should "set the parent object on the clients cache" do
        Network.expects(:find).never
        network = Network.create(:klass => "A")
        3.times {
          server = Server.new
          server.add_network(network)
        }
        assert_equal network, network.servers.first.networks.first
      end

      should "set the parent object on the clients cache from the other side of the relation" do
        Server.expects(:find).never
        network = Network.create(:klass => "A")
        3.times {
          server = Server.new
          network.add_server(server)
        }
        assert_equal network, network.servers.first.networks.first
      end

      should "work relations from both sides" do
        network_a = Network.create(:klass => "A")
        network_b = Network.create(:klass => "B")
        3.times {
          server = Server.new
          server.add_network(network_a)
          server.add_network(network_b)
        }
        assert_equal 3, network_a.servers.size
        network_a.servers.each do |server|
          assert_equal 2, server.networks.size
        end
        assert_equal 3, network_b.servers.size
        network_b.servers.each do |server|
          assert_equal 2, server.networks.size
        end
      end

      should "work relations from both sides - regardless from where the add was called" do
        network_a = Network.create(:klass => "A")
        network_b = Network.create(:klass => "B")
        3.times {
          server = Server.new
          network_a.add_server(server)
          network_b.add_server(server)
        }
        assert_equal 3, network_a.servers.size
        network_a.servers.each do |server|
          assert_equal 2, server.networks.size, server.network_ids.inspect
        end
        assert_equal 3, network_b.servers.size
        network_b.servers.each do |server|
          assert_equal 2, server.networks.size
        end
      end

      context "limit" do

        should "be able to limit the result set" do
          network = Network.create(:klass => "A")
          3.times {
            server = Server.new
            server.add_network(network)
          }
          assert_equal 2, network.servers(:limit => 2).size
        end

        should "use the given options in the cache-key" do
          network = Network.create(:klass => "A")
          3.times {
            server = Server.new
            server.add_network(network)
          }
          assert_equal 2, network.servers(:limit => 2).size
          assert_equal 3, network.servers(:limit => 3).size
        end

        should "be able to limit the result set - for both directions" do
          network_a = Network.create(:klass => "A")
          network_b = Network.create(:klass => "B")
          3.times {
            server = Server.new
            server.add_network(network_a)
            server.add_network(network_b)
          }
          assert_equal 2, network_a.servers(:limit => 2).size
          assert_equal 3, network_a.servers(:limit => 3).size

          assert_equal 2, network_a.servers.first.networks(:limit => 2).size
          assert_equal 1, network_a.servers.first.networks(:limit => 1).size
        end
      end

      context "order" do
        setup do
          @network = Network.create(:klass => "A")
          @network.created_at = Time.local(2000)
          @network.save!
          @network_b = Network.create(:klass => "B")
          @network_b.created_at = Time.local(2002)
          @network_b.save!
          3.times do |i|
            server = Server.new
            server.add_network(@network)
            server.add_network(@network_b)
            server.created_at = Time.local(2000 + i)
            server.save!
          end
        end

        should "support different order" do
          assert_nothing_raised do
            @network.servers(:order => :asc)
          end

          assert_nothing_raised do
            @network.servers(:order => :desc)
          end
        end

        should "reverse the order if :desc" do
          assert_equal @network.servers(:order => :asc).map(&:id).reverse, @network.servers(:order => :desc).map(&:id)
          server = @network.servers.first
          assert_equal server.networks(:order => :asc).map(&:id).reverse, server.networks(:order => :desc).map(&:id)
        end

        should "work with the limit option" do
          server = Server.new
          server.add_network(@network)
          server.add_network(@network_b)
          assert_not_equal @network.servers(:order => :asc, :limit => 3).map(&:id).reverse, @network.servers(:order => :desc, :limit => 3).map(&:id)
          assert_not_equal server.networks(:order => :asc, :limit => 1).map(&:id).reverse, server.networks(:order => :desc, :limit => 1).map(&:id)
        end
      end

      should "verify the given options for the accessor method" do
        network = Network.create(:klass => "A")
        assert_raise(ArgumentError) do
          network.servers(:foo => :bar)
        end
      end

      should "verify the given options for the association defintion" do
        assert_raise(ArgumentError) do
          Network.instance_eval do
            has_and_belongs_to_many :foo, :bar => :do
          end
        end
      end

      should "only fetch objects of the correct type" do
        network = Network.create(:klass => "A")
        server = Server.new
        server.network_ids = [network.id]
        server.save!

        comment = Comment.new
        comment.network = network
        comment.save!

        assert_equal 1, network.servers.size
      end

      should "getter should user cache" do
        network = Network.create(:klass => "A")
        server = Server.new
        server.network_ids = [network.id]
        server.save!
        network.servers
        assert_equal [server], network.instance_variable_get("@servers")[:all]
      end

      should "add methods to handle associated objects" do
        network = Network.create(:klass => "A")
        assert network.respond_to?(:add_server)
        assert network.respond_to?(:remove_server)
        assert network.respond_to?(:remove_all_servers)
      end

      should "add methods to handle associated objects - for the other side too" do
        server = Server.create
        assert server.respond_to?(:add_network)
        assert server.respond_to?(:remove_network)
        assert server.respond_to?(:remove_all_networks)
      end

      should 'ignore the cache when requesting explicit reload' do
        network = Network.create(:klass => "A")
        assert_equal [], network.servers
        server = Server.new
        server.network_ids = [network.id]
        server.save!
        assert_equal [server], network.servers(:force_reload => true)
      end

      should "use the correct view when handling inheritance" do
        network = Network.create
        subnet = Subnet.create
        server = Server.new
        server.network_ids = [network.id]
        server.save!
        assert_equal 1, network.servers.size
        server.update_attributes(:network_ids => nil, :subnet_ids => [subnet.id])
        assert_equal 1, subnet.servers.size
      end

      context "when adding items" do
        should "add the item to the internal cache" do
          network = Network.new(:klass => "C")
          server = Server.new
          assert_equal [], network.servers
          network.add_server(server)
          assert_equal [server], network.servers
          assert_equal [server], network.instance_variable_get("@servers")[:all]
        end

        should "raise an error when the added item is not an object of the expected class" do
          network = Network.new
          assert_raise(ArgumentError, 'excepted Server got String') do
            network.add_server('foo')
          end
        end

        should "save the added item" do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)
          assert !server.new_record?
        end

        should "save the added item - from both directions" do
          server = Server.new
          network = Network.create(:klass => "A")
          server.add_network(network)
          assert !server.new_record?
        end

        should 'set the forein key on the added object' do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)
          assert_equal [network.id], server.network_ids
        end

        should 'set the forein key on the added object - from both directions' do
          server = Server.new
          network = Network.create(:klass => "A")
          server.add_network(network)
          assert_equal [network.id], server.network_ids
        end

        should "adding multiple times doesn't hurt" do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)
          network.add_server(server)
          server.add_network(network)
          assert_equal [network.id], server.network_ids
          assert_equal [network.id], Server.find(server.id).network_ids
        end
      end

      context "when removing items" do
        should "should unset the foreign key" do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)

          network.remove_server(server)
          assert_equal [], server.network_ids
        end

        should "should unset the foreign key - from both directions" do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)

          server.remove_network(network)
          assert_equal [], server.network_ids
        end

        should "remove the item from the cache" do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)
          assert network.servers.include?(server)
          network.remove_server(server)
          assert !network.servers.any?{|s| server.id == s.id}
          assert_equal [], network.instance_variable_get("@servers")[:all]
        end

        should "remove the item from the cache - from both directions" do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)
          assert server.networks.include?(network)
          server.remove_network(network)
          assert !server.networks.any?{|n| network.id == n.id}
          assert_equal [], server.instance_variable_get("@networks")[:all]
        end

        should "save the removed item with the nullified foreign key" do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)

          network.remove_server(server)
          server = Server.find(server.id)
          assert_equal [], server.network_ids
        end

        should "save the removed item with the nullified foreign key - from both directions" do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)

          server.remove_network(network)
          server = Server.find(server.id)
          assert_equal [], server.network_ids
        end

        should 'raise an error when another object is the owner of the object to be removed' do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)

          other_server = Server.create
          assert_raise(ArgumentError) do
            network.remove_server(other_server)
          end
        end

        should 'raise an error when another object is the owner of the object to be removed - from both directions' do
          server = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server)

          other_network = Network.create
          assert_raise(ArgumentError) do
            server.remove_network(other_network)
          end
        end

        should 'raise an error when the object is the wrong type' do
          assert_raise(ArgumentError, 'excepted Server got String') do
            Network.new.remove_server('foo')
          end
          assert_raise(ArgumentError, 'excepted Network got String') do
            Server.new.remove_network('foo')
          end
        end
      end

      context "when removing all items" do
        should 'nullify the foreign keys on all referenced items' do
          server_1 = Server.new
          server_2 = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server_1)
          network.add_server(server_2)
          network.remove_all_servers
          server_1 = Server.find(server_1.id)
          server_2 = Server.find(server_2.id)
          assert_equal [], server_1.network_ids
          assert_equal [], server_2.network_ids
        end

        should 'nullify the foreign keys on all referenced items - from both directions' do
          server_1 = Server.new
          server_2 = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server_1)
          network.add_server(server_2)
          server_1.remove_all_networks
          server_1 = Server.find(server_1.id)
          server_2 = Server.find(server_2.id)
          assert_equal [], server_1.network_ids
          assert_equal [network.id], server_2.network_ids
        end

        should 'empty the cache' do
          server_1 = Server.new
          server_2 = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server_1)
          network.add_server(server_2)
          network.remove_all_servers
          assert_equal [], network.servers
          assert_equal [], network.instance_variable_get("@servers")[:all]
        end

        should 'empty the cache - from both directions' do
          server_1 = Server.new
          server_2 = Server.new
          network = Network.create(:klass => "A")
          network.add_server(server_1)
          network.add_server(server_2)
          server_1.remove_all_networks
          assert_equal [], server_1.networks
          assert_equal [], server_1.instance_variable_get("@networks")[:all]
        end

        context "when counting" do
          setup do
            @network = Network.create(:klass => "C")
            @server = Server.create
          end

          should "define a count method" do
            assert @network.respond_to?(:server_count)
            assert @server.respond_to?(:network_count)
          end

          should "cache the result" do
            assert_equal 0, @network.server_count
            Server.create(:network_ids => [@network.id])
            assert_equal 0, @network.server_count
            assert_equal 0, @network.instance_variable_get("@server_count")
            @network.instance_variable_set("@server_count", nil)
            assert_equal 1, @network.server_count
          end

          should "cache the result - from both directions" do
            assert_equal 0, @server.network_count
            @server.network_ids = [@network.id]
            @server.save!
            assert_equal 0, @server.network_count
            assert_equal 0, @server.instance_variable_get("@network_count")
            @server.instance_variable_set("@network_count", nil)
            assert_equal 1, @server.network_count
          end

          should "force reload even if cached" do
            assert_equal 0, @network.server_count
            Server.create(:network_ids => [@network.id])
            assert_equal 0, @network.server_count
            assert_equal 1, @network.server_count(:force_reload => true)
          end

          should "force reload even if cached - from both directions" do
            assert_equal 0, @server.network_count
            @server.network_ids = [@network.id]
            @server.save!
            assert_equal 0, @server.network_count
            assert_equal 1, @server.network_count(:force_reload => true)
          end

          should "count the number of belongs_to objects" do
            assert_equal 0, @network.server_count(:force_reload => true)
            Server.create(:network_ids => [@network.id])
            assert_equal 1, @network.server_count(:force_reload => true)
            Server.create(:network_ids => [@network.id])
            assert_equal 2, @network.server_count(:force_reload => true)
            Server.create(:network_ids => [@network.id])
            assert_equal 3, @network.server_count(:force_reload => true)
          end

          should "count the number of belongs_to objects - from both directions" do
            assert_equal 0, @server.network_count(:force_reload => true)
            @server.network_ids = [@network.id]
            @server.save!
            assert_equal 1, @server.network_count(:force_reload => true)
            @server.network_ids = [@network.id, Network.create.id]
            @server.save!
            assert_equal 2, @server.network_count(:force_reload => true)
          end

          should "not count non-releated objects" do
            Server.all.each{|s| s.delete}
            network_1 = Network.create(:klass => "A")
            network_2 = Network.create(:klass => "B")
            server_1 = Server.create
            server_2 = Server.create(:network_ids => [network_1.id])
            server_3 = Server.create(:network_ids => [network_1.id, network_2.id])
            assert_equal 3, Server.count
            assert_equal 2, network_1.server_count
            assert_equal 1, network_2.server_count
            assert_equal 0, server_1.network_count
            assert_equal 1, server_2.network_count
            assert_equal 2, server_3.network_count
          end

          should "not count deleted objects" do
            network = Network.create(:klass => "A")
            server = Server.create(:network_ids => [network.id])
            assert_equal 1, network.server_count(:force_reload => true)
            server.delete
            assert_equal 0, network.server_count(:force_reload => true)
          end

          should "not count deleted objects - from both directions" do
            network = Network.create(:klass => "A")
            server = Server.create(:network_ids => [network.id])
            assert_equal 1, server.network_count(:force_reload => true)
            network.delete
            assert_equal 0, server.network_count(:force_reload => true)
          end

        end
      end

      context "with deleted" do
        should "not fetch deleted objects" do
          network = Network.create(:klass => "A")
          server = Server.new
          server.network_ids = [network.id]
          server.save!
          assert_equal 1, network.servers(:force_reload => true).size
          assert_no_difference "Network.count" do
            assert_difference "Server.count", -1 do
              server.delete
            end
          end
          assert_equal 0, network.servers(:force_reload => true).size
        end

        should "not fetch deleted objects - from both directions" do
          network = Network.create(:klass => "A")
          server = Server.new
          server.network_ids = [network.id]
          server.save!
          assert_equal 1, server.networks(:force_reload => true).size
          assert_difference "Network.count", -1 do
            assert_no_difference "Server.count" do
              network.delete
            end
          end
          assert_equal 0, server.networks(:force_reload => true).size, server.networks(:force_reload => true).inspect
          assert_equal [], server.reload.network_ids
        end
      end


      context "with soft deleted" do

        should "not load soft deleted - items storing keys" do
          network = Network.create
          router = Router.new
          network.add_router(router)
          assert_equal 1, network.routers.size
          router.delete
          assert_equal 0, Router.count
          assert_equal 1, Router.count(:with_deleted => true)
          assert_equal 0, network.routers(:force_reload => true).size
          assert_equal 1, network.routers(:force_reload => true, :with_deleted => true).size
          router.delete!
          assert_equal 0, network.routers(:force_reload => true, :with_deleted => true).size
        end

        should "not count soft deleted - items storing keys" do
          network = Network.create
          router = Router.new
          network.add_router(router)
          assert_equal 1, network.routers.size
          router.delete
          assert_equal 0, Router.count
          assert_equal 1, Router.count(:with_deleted => true)
          assert_equal 0, network.router_count(:force_reload => true)
          assert_equal 1, network.router_count(:force_reload => true, :with_deleted => true)
          router.delete!
          assert_equal 0, network.router_count(:force_reload => true, :with_deleted => true)
        end

        should "not load soft deleted - items not storing keys: not supported" do
          book = Book.create
          author = Author.create
          author.add_book(book)
          author.delete
          assert_equal 0, Author.count
          assert_equal 1, Author.count(:with_deleted => true)
          assert_equal 0, book.authors(:force_reload => true).size
          assert_equal 0, book.authors(:force_reload => true, :with_deleted => true).size
        end

        should "not count soft deleted - items not storing keys: not supported" do
          book = Book.create
          author = Author.create
          author.add_book(book)
          author.delete
          assert_equal 0, Author.count
          assert_equal 1, Author.count(:with_deleted => true)
          assert_equal 0, book.author_count(:force_reload => true)
          assert_equal 0, book.author_count(:force_reload => true, :with_deleted => true)
        end

      end

    end
  end
end
