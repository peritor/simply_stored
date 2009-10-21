class LogItem < SimplyStored::Simple
  has_s3_attachment :log_data, :bucket => "bucket-for-monsieur", :access_key => 'abcdef', :secret_access_key => 'secret!'
end
