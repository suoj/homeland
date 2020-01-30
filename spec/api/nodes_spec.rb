# frozen_string_literal: true

require "rails_helper"
require "active_support/core_ext"

describe "API V3", "nodes", type: :request do
  let(:json) { JSON.parse(response.body) }
  describe "GET /api/nodes.json" do
    before do
      %w[fun ruby nodes].each_with_index { |n, i| create(:node, name: n, id: i + 1) }
    end

    it "should return the list of nodes" do
      get "/api/v3/nodes.json"
      assert_equal 200, response.status
      keyset = %w[id name]
      assert_equal 3, json["nodes"].size
      assert_has_keys json["nodes"][0], "id", "name", "topics_count", "summary", "section_id", "sort", "section_name", "updated_at"
      json["nodes"].each do |h|
        h.slice!(*keyset)
      end

      expected = [
        { "id" => 1, "name" => "fun" },
        { "id" => 2, "name" => "ruby" },
        { "id" => 3, "name" => "nodes" },
      ]
      assert_equal expected, json["nodes"]
    end
  end

  describe "GET /api/nodes/:id.json" do
    let(:node) { create(:node, topics_count: 100) }

    it "should work" do
      get "/api/v3/nodes/#{node.id}.json"
      assert_equal 200, response.status
      assert_has_keys json["node"], "id", "name", "topics_count", "summary", "section_id", "sort", "section_name", "updated_at"
      assert_equal 100, json["node"]["topics_count"]
    end
  end
end
