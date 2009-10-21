require 'rubygems'
require 'webrick'
require 'builder'
require 'simplerdb/db'
require 'simplerdb/client_exception'

module SimplerDB
  
  # A WEBrick servlet to handle API requests over REST
  class RESTServlet < WEBrick::HTTPServlet::AbstractServlet
      
    def do_GET(req, res)
      action = req.query["Action"]
      
      begin
        if action.nil?
          # Raise an error
          raise ClientException.new(:MissingAction, "No action was supplied with this request")
        else
          # Process the action appropriately
          xml = send("do_#{action.downcase}", req)
          res.body = xml
          res.status = 200
        end
      rescue ClientException => e
        res.body = error_xml(e.code, e.msg)
        res.status = 400 # What is the right status?
      end
      
      res['content-type'] = 'text/xml'
    end

    alias do_POST do_GET
    alias do_DELETE do_GET
    
    # Handle CreateDomain requests
    def do_createdomain(req)
      name = req.query["DomainName"]
      DB.instance.create_domain(name)
      build_result("CreateDomain")
    end
    
    # Handle ListDomains requests
    def do_listdomains(req)
      max = req.query["MaxNumberOfDomains"]
      next_token = req.query["NextToken"]
      
      max = max.to_i if max
      domains,token = DB.instance.list_domains(max, next_token)
      
      build_result("ListDomains") do |doc|
        doc.ListDomainsResult do
          if domains
            domains.each do |domain|
              doc.DomainName domain
            end
          end
          
          if token
            doc.NextToken token
          end
        end
      end
    end
    
    
    # DeleteDomains requests
    def do_deletedomain(req)
      name = req.query["DomainName"]
      DB.instance.delete_domain(name)
      build_result("DeleteDomain")  
    end
    
    # PutAttributes requests
    def do_putattributes(req)
      domain_name = req.query["DomainName"]
      item_name = req.query["ItemName"]
      attrs = parse_attribute_args(req)
      DB.instance.put_attributes(domain_name, item_name, attrs)
      build_result("PutAttributes")
    end
    
    # DeleteAttributes requests
    def do_deleteattributes(req)
      domain_name = req.query["DomainName"]
      item_name = req.query["ItemName"]
      attrs = parse_attribute_args(req)
      DB.instance.delete_attributes(domain_name, item_name, attrs)
      build_result("DeleteAttributes")
    end
    
    # GetAttributes request
    def do_getattributes(req)
      domain_name = req.query["DomainName"]
      item_name = req.query["ItemName"]
      attr_name = req.query["AttributeName"]
      attrs = DB.instance.get_attributes(domain_name, item_name)
      
      build_result("GetAttributes") do |doc|
        doc.GetAttributesResult do
          if attrs
            attrs.each do |attr|
              doc.Attribute do
                doc.Name attr.name
                doc.Value attr.value
              end
            end
          end
        end
      end
    end
    
    # Query request
    def do_query(req)
      domain_name = req.query["DomainName"]
      max_items = req.query["MaxItems"].to_i
      max_items = 100 if (max_items < 1 || max_items > 250)
      next_token = req.query["NextToken"]
      query = req.query["QueryExpression"]
      
      results,token = DB.instance.query(domain_name, query, max_items, next_token)
      build_result("Query") do |doc|
        doc.QueryResult do
          if results
            results.each do |res|
              doc.ItemName res.name
            end
          end
        
          if token
            doc.NextToken token
          end
        end
      end
    end
    
    # Build a result for the given action.
    # The given block will add action-specific return fields.
    def build_result(action)
      xml = ''
      doc = Builder::XmlMarkup.new(:target => xml)
        doc.tag!("#{action}Response", :xmlns => "http://sdb.amazonaws.com/doc/2007-11-07") do
          if block_given?
            yield doc
          end
          
          doc.ResponseMetadata do
            doc.RequestId "1234"
            doc.BoxUsage "0"
          end
        end
        
      xml
    end
    
    # Return the error response for the given error code and message
    def error_xml(code, msg)
      xml = ''
      doc = Builder::XmlMarkup.new(:target => xml)
      
      doc.Response do
        doc.Errors do
          doc.Error do
            doc.Code code.to_s
            doc.Message msg
            doc.BoxUsage "0"
          end
        end
        
        doc.RequestID  "1234"
      end
      
      xml
    end 
    
    def parse_attribute_args(req)
      args = []
      for i in (0...100)
        name = req.query["Attribute.#{i}.Name"]
        value = req.query["Attribute.#{i}.Value"]
        replace = (req.query["Attribute.#{i}.Replace"] == "true")
        if name && value
          args << AttributeParam.new(name, value, replace)
        end
      end
      
      args
    end
  end
  
end