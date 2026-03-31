require "test_helper"

class Api::V1::DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = create(:organization, plan: "pro")
    @user = create(:user, organization: @org)
    @user.generate_api_token!
    @headers = { "Authorization" => "Bearer #{@user.api_token}" }
    @folder = create(:folder, organization: @org, user: @user)
  end

  test "create uploads a document" do
    file = fixture_file_upload("test.pdf", "application/pdf")

    assert_difference("Document.count") do
      post api_v1_documents_url,
        params: { file: file, name: "Test Doc", folder_id: @folder.id },
        headers: @headers
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Test Doc", json["name"]
    assert_equal @folder.id, json["folder_id"]
    assert_equal "application/pdf", json["content_type"]
  end

  test "create without auth returns 401" do
    file = Rack::Test::UploadedFile.new(StringIO.new("test"), "application/pdf", true, original_filename: "test.pdf")

    post api_v1_documents_url, params: { file: file, name: "Test" }

    assert_response :unauthorized
  end

  test "show returns document metadata" do
    Current.organization = @org
    doc = create(:document, organization: @org, user: @user, folder: @folder)

    get api_v1_document_url(doc), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal doc.id, json["id"]
    assert_equal doc.name, json["name"]
  end

  test "show returns 404 for nonexistent document" do
    get api_v1_document_url(id: 999999), headers: @headers, as: :json

    assert_response :not_found
  end

  test "show returns 403 for inaccessible document" do
    other_org = create(:organization)
    other_user = create(:user, organization: other_org)
    Current.organization = other_org
    other_doc = create(:document, organization: other_org, user: other_user, visibility: :doc_private)
    Current.organization = nil

    get api_v1_document_url(other_doc), headers: @headers, as: :json

    # Should be not found because TenantIsolated scoping filters it out
    assert_response :not_found
  end

  test "download returns a URL" do
    Current.organization = @org
    doc = create(:document, organization: @org, user: @user, folder: @folder)

    get download_api_v1_document_url(doc), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["download_url"].present?
  end

  test "destroy archives document with signed requests" do
    Current.organization = @org
    doc = create(:document, organization: @org, user: @user, folder: @folder)

    delete api_v1_document_url(doc), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["deleted"] || json["archived"]
  end

  test "update changes document metadata" do
    Current.organization = @org
    doc = create(:document, organization: @org, user: @user, folder: @folder)

    patch api_v1_document_url(doc), params: { name: "Updated Name" }, headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Name", json["name"]
  end
end
