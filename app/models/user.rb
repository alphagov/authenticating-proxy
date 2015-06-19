require "gds-sso/user"

class User
  include Mongoid::Attributes::Dynamic
  include Mongoid::Document
  include Mongoid::Timestamps
  include GDS::SSO::User

  field "disabled",                type: Boolean, default: false
  field "email",                   type: String
  field "name",                    type: String
  field "organisation_content_id", type: String
  field "organisation_slug",       type: String
  field "permissions",             type: Array
  field "remotely_signed_out",     type: Boolean, default: false
  field "uid",                     type: String
end
