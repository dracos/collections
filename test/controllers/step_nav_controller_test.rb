require "test_helper"

describe StepNavController do
  it "returns a 404 when the page doesn't exist" do
    slug = SecureRandom.hex
    stub_content_store_does_not_have_item("/#{slug}")

    get :show, params: { slug: slug }

    assert_response 404
  end

  it "returns a 403 when the user is not authorised" do
    slug = SecureRandom.hex
    url = content_store_endpoint + "/content/" + slug
    stub_request(:get, url).to_return(status: 403, headers: {})

    get :show, params: { slug: slug }

    assert_response 403
  end
end
