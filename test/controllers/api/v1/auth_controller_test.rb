require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = create(:organization)
    @user = create(:user, organization: @org, email: "test@example.com", password: "password123")
  end

  test "login with valid credentials returns token" do
    post api_v1_auth_login_url, params: { email: "test@example.com", password: "password123" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert_equal @user.email, json["user"]["email"]
    assert_equal @org.name, json["user"]["organization"]
  end

  test "login with invalid password returns 401" do
    post api_v1_auth_login_url, params: { email: "test@example.com", password: "wrong" }, as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Invalid email or password", json["error"]
  end

  test "login with nonexistent email returns 401" do
    post api_v1_auth_login_url, params: { email: "nobody@example.com", password: "password123" }, as: :json

    assert_response :unauthorized
  end

  test "login with deleted user returns 401" do
    @user.soft_delete!
    post api_v1_auth_login_url, params: { email: "test@example.com", password: "password123" }, as: :json

    assert_response :unauthorized
  end

  test "login is case insensitive for email" do
    post api_v1_auth_login_url, params: { email: "TEST@EXAMPLE.COM", password: "password123" }, as: :json

    assert_response :success
  end

  test "logout revokes token" do
    @user.generate_api_token!
    token = @user.api_token

    delete api_v1_auth_logout_url, headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_response :success
    @user.reload
    assert_nil @user.api_token
  end

  test "logout without token returns 401" do
    delete api_v1_auth_logout_url, as: :json

    assert_response :unauthorized
  end
end
