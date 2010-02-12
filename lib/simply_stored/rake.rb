namespace :simply_stored do
  desc "delete all design documents"
  task :delete_design_documents do
    require File.dirname(__FILE__) + "/couch"
    if database = ENV['DATABASE']
      deleted = SimplyStored::Couch.delete_all_design_documents(database)
      puts "deleted #{deleted} design documents in #{database}"
    else
      puts "please specify which database to clear: DATABASE=http://localhost:5984/simply_stored rake simply_stored:delete_design_documents"
    end
  end
end