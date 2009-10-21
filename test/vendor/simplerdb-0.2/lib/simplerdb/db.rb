require 'singleton'
require 'simplerdb/query_language'

module SimplerDB
  
  class Domain
    attr_accessor :name, :items
    
    def initialize(name)
      @name = name
      @items = Hash.new { |hash, key| hash[key] = Item.new(key) }
    end
  end
  
  class Item
    attr_accessor :name, :attributes
    
    def initialize(name)
      @name = name
      @attributes = Hash.new { |hash, key| hash[key] = [] }
    end
    
    def put_attribute(attr, replace = false)
      @attributes[attr.name].clear if replace
      @attributes[attr.name] << attr 
    end
    
    def delete_attribute(attr)
      if attr.value.nil?
        @attributes[attr.name].clear
      else
        @attributes[attr.name].delete(attr)
      end
      
      if @attributes[attr.name].size == 0
        @attributes.delete(attr.name)
      end
    end
    
    def get_attributes(attribute_name = nil)
      attrs = []
      
      @attributes.each do |key, value|
        if (attribute_name.nil? || attribute_name == key)
          attrs += value
        end
      end
      
      return attrs
    end
  end
  
  class Attribute
    attr_accessor :name, :value
    
    def initialize(name, value)
      @name = name
      @value = value
    end
    
    def ==(other)
      @name == other.name && @value == other.value
    end
  end
  
  class AttributeParam < Attribute
    attr_accessor :replace
    
    def initialize(name, value, replace = false)
      super(name, value)
      @replace = replace
    end
    
    def to_attr
      Attribute.new(self.name, self.value)
    end
  end
  
  # The main SimplerDB class, containing methods that correspond to the
  # AWS API.
  class DB
    include Singleton
    
    def initialize
      reset
    end
    
    # For testing
    def reset
      @domains = {}
      @query_executor = QueryExecutor.new
    end
    
    def create_domain(name)
      @domains[name] ||= Domain.new(name)  
    end
    
    def delete_domain(name)
      @domains.delete(name)
    end
    
    def list_domains(max = 100, token = 0)
      doms = []
      count = 0
      token = 0 unless token
      @domains.keys.each do |domain|
        break if doms.size == max
        doms << domain if count >= token.to_i
        count += 1
      end
      
      if (count >= @domains.size)
        return doms,nil
      else
        return doms,count
      end
    end
    
    def get_attributes(domain_name, item_name, attribute_name = nil)
      domain = @domains[domain_name]
      item = domain.items[item_name]
      return item.get_attributes(attribute_name)
    end
    
    def put_attributes(domain_name, item_name, attribute_params)
      domain = @domains[domain_name]
      item = domain.items[item_name]
      attribute_params.each { |attr| item.put_attribute(attr.to_attr, attr.replace) } 
    end
    
    def delete_attributes(domain_name, item_name, attributes)
      domain = @domains[domain_name]
      item = domain.items[item_name]
      if attributes.empty?
        domain.items.delete(item_name)
      else
        attributes.each { |attr| item.delete_attribute(attr) } 
      end
    end
    
    def query(domain, query, max = 100, token = 0)
      @query_executor.do_query(query, @domains[domain], max, token)
    end
  end
  
end
