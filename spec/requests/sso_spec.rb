RSpec.describe "GDS-SSO requests", type: :request do
  let(:upstream_uri) { ENV["GOVUK_UPSTREAM_URI"] }
  let(:sign_out_path) { "/auth/gds/sign_out" }

  it "does not proxy requests for GDS-SSO routes" do
    get sign_out_path

    expect(response.status).to eq(302)
    expect(response["Location"]).to eq("#{Plek.new.external_url_for('signon')}/users/sign_out")
  end
end
