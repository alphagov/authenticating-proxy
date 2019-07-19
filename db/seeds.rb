# Create a default user for GDS::SSO
user = User.new(
  name: "Bobby Bob",
  email: "bob@alphagov.co.uk",
  organisation_content_id: "af07d5a5-df63-4ddc-9383-6a666845ebe9",
  uid: "b3351570-7af1-0137-91b6-02e3ce870912"
)
user.permissions = ["signin"]
user.save!
