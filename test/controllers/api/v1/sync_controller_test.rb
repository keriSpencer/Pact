require "test_helper"

class Api::V1::SyncControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = create(:organization)
    @user = create(:user, organization: @org)
    @user.generate_api_token!
    @headers = { "Authorization" => "Bearer #{@user.api_token}" }
    Current.organization = @org
    @folder = create(:folder, organization: @org, user: @user, name: "Sync")
  end

  test "status returns documents in folder" do
    doc = create(:document, organization: @org, user: @user, folder: @folder)

    get api_v1_sync_status_url(folder_id: @folder.id), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["server_time"].present?
    assert_equal @folder.id, json["folder"]["id"]
    assert_equal 1, json["documents"].length
    assert_equal doc.id, json["documents"].first["id"]
    assert_equal [], json["deleted_ids"]
  end

  test "status with since returns only recent documents" do
    old_doc = create(:document, organization: @org, user: @user, folder: @folder)
    old_doc.update_columns(created_at: 2.days.ago, updated_at: 2.days.ago)
    new_doc = create(:document, organization: @org, user: @user, folder: @folder)

    get api_v1_sync_status_url(folder_id: @folder.id, since: 1.day.ago.iso8601), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    doc_ids = json["documents"].map { |d| d["id"] }
    assert_includes doc_ids, new_doc.id
    refute_includes doc_ids, old_doc.id
  end

  test "status returns deleted_ids for archived documents since timestamp" do
    doc = create(:document, organization: @org, user: @user, folder: @folder)
    doc.update!(status: :archived)

    get api_v1_sync_status_url(folder_id: @folder.id, since: 1.minute.ago.iso8601), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json["deleted_ids"], doc.id
  end

  test "status includes subfolder documents" do
    subfolder = create(:folder, organization: @org, user: @user, name: "Sub", parent: @folder)
    doc = create(:document, organization: @org, user: @user, folder: subfolder)

    get api_v1_sync_status_url(folder_id: @folder.id), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    doc_ids = json["documents"].map { |d| d["id"] }
    assert_includes doc_ids, doc.id
  end

  test "status without auth returns 401" do
    get api_v1_sync_status_url(folder_id: @folder.id), as: :json

    assert_response :unauthorized
  end

  test "status with invalid folder returns 404" do
    get api_v1_sync_status_url(folder_id: 999999), headers: @headers, as: :json

    assert_response :not_found
  end
end
