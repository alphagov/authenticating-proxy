require 'rails_helper'

RSpec.describe "Proxying requests", type: :request do
  let(:body) { "abc" }
  let(:upstream_path) { "/foo" }
  let(:upstream_uri) { ENV['GOVUK_UPSTREAM_URI'] }

  context "unauthenticated user" do
    around do |example|
      ENV['GDS_SSO_MOCK_INVALID'] = '§1'
      example.run
      ENV.delete('GDS_SSO_MOCK_INVALID')
    end

    it "redirects the user for authentication" do
      get upstream_path

      expect(response.status).to eq(302)
      expect(response["Location"]).to eq("http://www.example.com/auth/gds")
    end
  end

  context "authenticated user" do
    let(:authenticated_user_id) { User.first.id }
    before do
      stub_request(:get, upstream_uri + upstream_path).to_return(body: body)
      get upstream_path
    end

    it "proxies the request to the upstream server" do
      expect(response.body).to eq(body)
    end

    it "includes an identifier for the authenticated user in the upstream request headers" do
      expect(WebMock).to have_requested(:get, upstream_uri + upstream_path).
        with(headers: { 'X-Govuk-Authenticated-User' => authenticated_user_id })
    end
  end
end
