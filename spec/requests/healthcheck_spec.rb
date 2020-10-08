require "rails_helper"

RSpec.describe "healthcheck path", type: :request do
  it "responds with 'OK'" do
    get "/healthcheck"

    expect(response.status).to eq(200)
    expect(response.body).to eq("OK")
  end
end
