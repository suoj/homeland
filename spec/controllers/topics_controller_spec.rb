# frozen_string_literal: true

require "rails_helper"

describe TopicsController, type: :controller do
  render_views
  let(:topic) { create :topic, user: user }
  let(:user) { create :avatar_user }
  let(:newbie) { create :newbie }
  let(:node) { create :node }
  let(:admin) { create :admin }
  let(:team) { create :team }

  describe ":index" do
    it "should have an index action" do
      get :index
      assert_equal 200, response.status
    end

    it "should work when login" do
      sign_in user
      get :index
      assert_equal 200, response.status
    end

    it "should 404 with non integer :page value" do
      get :index, params: { page: "2/*" }
      assert_equal 200, response.status
    end
  end

  describe ":feed" do
    it "should have a feed action" do
      get :feed
      assert_equal "application/xml; charset=utf-8", response.headers["Content-Type"]
      assert_equal 200, response.status
    end
  end

  describe ":last" do
    it "should have a recent action" do
      get :last
      assert_equal 200, response.status
    end
  end

  describe ":excellent" do
    it "should have a excellent action" do
      get :excellent
      assert_equal 200, response.status
    end
  end

  describe ":banned" do
    it "should have a banned action" do
      get :banned
      assert_equal 200, response.status
    end
  end

  describe ":favorites" do
    it "should have a recent action" do
      sign_in user
      get :favorites
      assert_equal 200, response.status
    end
  end

  describe ":node" do
    it "should have a node action" do
      get :node, params: { id: topic.node_id }
      assert_equal 200, response.status
    end
  end

  describe ":node_feed" do
    it "should have a node_feed action" do
      get :node_feed, params: { id: topic.node_id }
      assert_equal 200, response.status
    end
  end

  describe ":no_reply" do
    it "should have a no_reply action" do
      get :no_reply
      assert_equal 200, response.status
    end
  end

  describe ":last_reply" do
    it "should have a no_reply action" do
      get :last_reply
      assert_equal 200, response.status
    end
  end

  describe ":popular" do
    it "should have a popular action" do
      get :popular
      assert_equal 200, response.status
    end
  end

  describe ":new" do
    describe "unauthenticated" do
      it "should not allow anonymous access" do
        get :new
        refute_equal 200, response.status
      end
    end

    describe "authenticated" do
      it "should allow access from authenticated user" do
        sign_in user
        get :new
        assert_equal 200, response.status
      end

      it "should render 404 for invalid node id" do
        sign_in user
        get :new, params: { node: (node.id + 1) }
        refute_equal 200, response.status
      end

      it "should not allow access from newbie user" do
        allow(Setting).to receive(:newbie_limit_time).and_return("100000")
        sign_in newbie
        get :new
        refute_equal 200, response.status
      end
    end
  end

  describe ":edit" do
    context "unauthenticated" do
      it "should not allow anonymous access" do
        get :edit, params: { id: topic.id }
        refute_equal 200, response.status
      end
    end

    context "authenticated" do
      context "own topic" do
        it "should allow access from authenticated user" do
          sign_in user
          get :edit, params: { id: topic.id }
          assert_equal 200, response.status
          assert_equal true, response.body.include?('tb="edit-topic"')
        end
      end

      context "other's topic" do
        it "should not allow edit other's topic" do
          other_user = create :user
          topic_of_other_user = create(:topic, user: other_user)
          sign_in user
          get :edit, params: { id: topic_of_other_user.id }
          refute_equal 200, response.status
        end
      end
    end
  end

  describe ":create" do
    context "unauthenticated" do
      it "should not allow anonymous access" do
        post :create, params: { title: "Hello world" }
        refute_equal 200, response.status
      end
    end

    context "authenticated" do
      it "should allow access from authenticated user" do
        sign_in user
        post :create, params: { format: :js, topic: { title: "new topic", body: "new body", node_id: node } }
        assert_equal 200, response.status
      end
      it "should allow access from authenticated user with team" do
        sign_in user
        post :create, params: { format: :js, topic: { title: "new topic", body: "new body", node_id: node, team_id: team.id } }
        assert_equal 200, response.status
      end
    end
  end

  describe ":preview" do
    it "should work" do
      sign_in user
      post :preview, params: { format: :json, body: "new body" }
      assert_equal 200, response.status
    end
  end

  describe ":update" do
    it "should work" do
      sign_in user
      topic = create :topic, user_id: user.id, title: "new title", body: "new body"
      put :update, params: { format: :js, id: topic.id, topic: { title: "new topic 2", body: "new body 2" } }
      assert_equal 200, response.status
    end

    it "should update with admin user" do
      # new_node = create(:node)
      sign_in admin
      put :update, params: { format: :js, id: topic.id, topic: { title: "new topic 2", body: "new body 2", node_id: node } }
      assert_equal 200, response.status
      topic.reload
      assert_equal true, topic.lock_node
    end
  end

  describe ":destroy" do
    it "should work" do
      sign_in user
      topic = create :topic, user_id: user.id, title: "new title", body: "new body"
      delete :destroy, params: { id: topic.id }
      assert_redirected_to topics_path
    end
  end

  describe ":favorite" do
    it "should work" do
      sign_in user
      post :favorite, params: { id: topic.id }
      assert_equal 200, response.status
      assert_equal "1", response.body
    end
  end

  describe ":unfavorite" do
    it "should work" do
      sign_in user
      delete :unfavorite, params: { id: topic.id }
      assert_equal 200, response.status
      assert_equal "1", response.body
    end
  end

  describe ":follow" do
    it "should work" do
      sign_in user
      post :follow, params: { id: topic.id }
      assert_equal 200, response.status
      assert_equal "1", response.body
    end
  end

  describe ":unfollow" do
    it "should work" do
      sign_in user
      delete :unfollow, params: { id: topic.id }
      assert_equal 200, response.status
      assert_equal "1", response.body
    end
  end

  describe "#show" do
    it "should clear user mention notification when show topic" do
      user = create :user
      topic = create :topic, body: "@#{user.login}"
      create :reply, body: "@#{user.login}", topic: topic, like_by_user_ids: [user.id]
      sign_in user
      expect do
        get :show, params: { id: topic.id }
      end.to change(user.notifications.unread, :count).by(-2)
    end
  end

  describe "#excellent" do
    it "should not allow user suggest" do
      sign_in user
      post :action, params: { id: topic, type: "excellent" }
      assert_equal false, topic.reload.excellent?
    end

    it "should not allow user suggest by admin" do
      sign_in admin
      post :action, params: { id: topic, type: "excellent" }
      assert_equal true, topic.reload.excellent?
    end
  end

  describe "#normal" do
    context "suggested topic" do
      let!(:topic) { create(:topic, grade: :excellent) }

      it "should not allow user suggest" do
        sign_in user
        post :action, params: { id: topic, type: "normal" }
        assert_equal true, topic.reload.excellent?
      end

      it "should not allow user suggest by admin" do
        sign_in admin
        post :action, params: { id: topic, type: "normal" }
        assert_equal false, topic.reload.excellent?
      end
    end
  end

  describe "#ban" do
    describe "GET /topics/:id/ban" do
      it "should user not work" do
        sign_in user
        get :ban, params: { id: topic }, xhr: true
        assert_equal 302, response.status
      end

      it "should admin work" do
        sign_in admin
        get :ban, params: { id: topic }, xhr: true
        assert_equal 200, response.status
      end
    end

    describe "POST /topics/:id/action" do
      it "should not allow user ban" do
        sign_in user
        post :action, params: { id: topic, type: "ban" }
        assert_equal false, topic.reload.ban?
      end

      it "should allow by admin" do
        sign_in admin
        post :action, params: { id: topic, type: "ban" }
        assert_equal 302, response.status
        assert_equal true, topic.reload.ban?

        expect do
          post :action, params: { id: topic, type: "ban", reason: "Foobar" }
        end.to change(topic.replies, :count).by(1)
        r = topic.replies.last
        assert_equal "ban", r.action
        assert_equal "Foobar", r.body

        expect do
          post :action, params: { id: topic, type: "ban", reason: "Foobar", reason_text: "Barfoo" }
        end.to change(topic.replies, :count).by(1)
        r = topic.replies.last
        assert_equal "ban", r.action
        assert_equal "Barfoo", r.body
      end
    end
  end

  describe "#close" do
    it "should not allow user close" do
      sign_in user
      post :action, params: { id: topic, type: "close" }
      assert_equal false, topic.reload.ban?
    end

    it "should not allow user suggest by admin" do
      sign_in admin
      post :action, params: { id: topic, type: "close" }
      assert_equal 302, response.status
      assert_equal true, topic.reload.closed_at.present?
    end
  end

  describe "#open" do
    it "should not allow user close" do
      sign_in user
      post :action, params: { id: topic, type: "open" }
      assert_equal false, topic.reload.ban?
    end

    it "should not allow user suggest by admin" do
      sign_in admin
      topic.close!
      post :action, params: { id: topic, type: "open" }
      assert_equal 302, response.status
      assert_nil topic.reload.closed_at
    end
  end
end
