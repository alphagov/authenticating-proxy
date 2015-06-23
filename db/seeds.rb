# Create a default user for GDS::SSO
user = User.new(name: "Bobby Bob", email: "bob@alphagov.co.uk")
user.permissions = ["signin"]
user.save!
