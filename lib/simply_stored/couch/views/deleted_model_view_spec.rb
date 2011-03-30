module SimplyStored
  module Couch
    module Views
      class DeletedModelViewSpec < CouchPotato::View::CustomViewSpec
        def map_function
          <<-eos
            function(doc) {
              if (doc.ruby_class && doc.ruby_class == '#{@klass.name}') {
                if (doc['#{@klass.soft_delete_attribute}'] && doc['#{@klass.soft_delete_attribute}'] != null){
                  // "soft" deleted
                }else{
                  emit(doc.created_at, 1);
                }
              }
            }
          eos
        end

        def reduce_function
          '_sum'
        end
        
        def view_parameters
          _super = super
          if _super[:reduce]
            _super
          else
            {:include_docs => true, :reduce => false}.merge(_super)
          end
        end
        
        def process_results(results)
          if count?
            results['rows'].first.try(:[], 'value') || 0
          else
            results['rows'].map { |row| row['doc'] || row['id'] }
          end
        end

      end
    end
  end
end