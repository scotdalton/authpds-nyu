require 'test_helper'
class UserSessionTest < ActiveSupport::TestCase

  def setup
    activate_authlogic
    controller.session[:session_id] = "FakeSessionID"
    controller.cookies[:iPlanetDirectoryPro] = { :value => VALID_OPENSSO_FOR_NYU }
  end

  test "valid_sso_session" do
    user_session = UserSession.new
    VCR.use_cassette('valid_sso_session') do
      assert(user_session.valid_sso_session?)
    end
  end

  test "invalid_sso_session" do
    controller.cookies[:iPlanetDirectoryPro] = { :value => INVALID_OPENSSO }
    VCR.use_cassette('invalid_sso_session') do
      user_session = UserSession.new
      assert(!user_session.valid_sso_session?)
    end
  end

  test "find" do
    user_session = UserSession.new
    assert_nil(controller.session["authpds_credentials"])
    assert_nil(user_session.send(:attempted_record))
    assert_nil(user_session.record)
    VCR.use_cassette('find') do
      assert_nothing_raised {
        user_session = UserSession.find
      }
    end
  end

  test "logout_url" do
    user_session = UserSession.new
    assert_equal(
      "https://logindev.library.nyu.edu/logout?url=http%3A%2F%2Frailsapp.library.nyu.edu",
        user_session.logout_url)
  end

  test "aleph_bor_auth" do
    user_session = UserSession.new
    VCR.use_cassette('bor_auth') do
      bor_auth = user_session.aleph_bor_auth("N12162279", "d4465aacaa645f2164908cd4184c09f0", "NYU50", "BOBST")
      assert_equal("89", bor_auth.permissions[:bor_status])
      assert_equal("CB", bor_auth.permissions[:bor_type])
      assert_equal("Y", bor_auth.permissions[:hold_on_shelf])
    end
  end

  test "aleph_bor_auth_permissions" do
    user_session = UserSession.new
    VCR.use_cassette('bor_auth_permissions') do
      permissions = user_session.aleph_bor_auth_permissions("N12162279", "d4465aacaa645f2164908cd4184c09f0", "NYU50", "BOBST")
      assert_equal("89", permissions[:bor_status])
      assert_equal("CB", permissions[:bor_type])
      assert_equal("Y", permissions[:hold_on_shelf])
    end
  end

  test "non opensso user" do
    controller.cookies[:PDS_HANDLE] = { :value => VALID_PDS_HANDLE_FOR_NEWSCHOOL }
    VCR.use_cassette('non opensso user') do
      assert_nothing_raised do
        user_session = UserSession.find
      end
    end
  end
  
  test "opensso user" do
    controller.cookies[:PDS_HANDLE] = { :value => VALID_PDS_HANDLE_FOR_NYU }
    VCR.use_cassette('opensso user') do
      assert_nothing_raised do
        user_session = UserSession.find
      end
    end
  end
end