GDS::SSO.config do |config|
  config.user_model   = 'User'
  config.oauth_id     = ENV['OAUTH_ID'] || 'cffdb8d8df2b3c8ec8e156ff4763d6315603bb89a812ce297691d8536510da38'
  config.oauth_secret = ENV['OAUTH_SECRET'] || 'ec4d814b1d2942da98e0a053c0e2fe5d6d85f1700a4465701b69774b3cdc6655'
  config.oauth_root_url = Plek.new.external_url_for('signon')
end
