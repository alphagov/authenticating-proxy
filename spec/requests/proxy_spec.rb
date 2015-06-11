require 'rails_helper'

RSpec.describe "Proxying requests", type: :request do
  let(:body) { "abc" }
  let(:path) { "/foo" }
  let(:upstream_uri) { ENV['GOVUK_UPSTREAM_URI'] }

  it "proxies an HTTP request unchanged" do
    stub = stub_request(:get, upstream_uri + path).to_return(body: body)

    get path

    expect(response.body).to eq(body)
  end
end
