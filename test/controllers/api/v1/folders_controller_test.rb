require "test_helper"

class Api::V1::FoldersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = create(:organization)
    @user = create(:user, organization: @org)
    @user.generate_api_token!
    @headers = { "Authorization" => "Bearer #{@user.api_token}" }
  end

  test "index lists folders" do
    Current.organization = @org
    create(:folder, organization: @org, user: @user, name: "Contracts")
    create(:folder, organization: @org, user: @user, name: "Invoices")

    get api_v1_folders_url, headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json.length
    names = json.map { |f| f["name"] }
    assert_includes names, "Contracts"
    assert_includes names, "Invoices"
  end

  test "index without auth returns 401" do
    get api_v1_folders_url, as: :json

    assert_response :unauthorized
  end

  test "create makes a new folder" do
    assert_difference("Folder.count") do
      post api_v1_folders_url,
        params: { name: "Desktop Sync" },
        headers: @headers, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Desktop Sync", json["name"]
  end

  test "create with parent folder" do
    Current.organization = @org
    parent = create(:folder, organization: @org, user: @user, name: "Parent")

    post api_v1_folders_url,
      params: { name: "Child", parent_id: parent.id },
      headers: @headers, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal parent.id, json["parent_id"]
  end

  test "show returns folder with documents" do
    Current.organization = @org
    folder = create(:folder, organization: @org, user: @user, name: "Test")
    create(:document, organization: @org, user: @user, folder: folder, name: "doc1.pdf")

    get api_v1_folder_url(folder), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Test", json["name"]
    assert_equal 1, json["documents"].length
  end
end
