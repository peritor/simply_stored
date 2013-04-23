module SimplyStored
  module Couch
    module Paginator
      def self.included(base)
        base.extend(ClassMethods)
      end
      module ClassMethods
        def build_pagination(options = {})
          params = {}
          params[:per_page] = options[:per_page] || 10
          params[:page] = options[:page] || 1
          self.page_params = params
          self
        end

        def build_pagination_params
          hash = {}
          hash[:skip] = page_params[:page].to_i * page_params[:per_page].to_i if page_params[:page] and page_params[:per_page]
          hash[:limit] = page_params[:per_page] if page_params[:per_page]
          hash
        end
        
      end
    end
  end
end



