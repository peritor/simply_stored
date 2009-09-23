module SimplyStored
  module Couch
    module Views
      class ArrayPropertyViewSpec < CouchPotato::View::ModelViewSpec
        def map_function
          "function(doc) {
             if(doc.ruby_class && doc.ruby_class == '#{@klass.name}') {
               if (#{formatted_key(key)}.constructor.toString().match(/function Array()/)) {
                 for (var i in #{formatted_key(key)}) {
                   emit(#{formatted_key(key)}[i], null);
                 }
               } else {
                 emit(#{formatted_key(key)}, null);
               }
             }
           }"
        end

      end
    end
  end
end