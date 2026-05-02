# frozen_string_literal: true

RSpec.describe SmartCacheTenant::CacheableRelation do
  describe "cached reads" do
    it "caches load results" do
      created = Project.create!(tenant_id: 1, name: "Alpha")

      first = Project.where(tenant_id: 1).load.to_a
      Project.where(id: created.id).delete_all
      second = Project.where(tenant_id: 1).load.to_a

      expect(first.map(&:id)).to eq([created.id])
      expect(second.map(&:id)).to eq([created.id])
    end

    it "caches calculate results" do
      Project.create!(tenant_id: 1, name: "Alpha")

      first_count = Project.where(tenant_id: 1).count
      Project.where(tenant_id: 1).delete_all
      second_count = Project.where(tenant_id: 1).count

      expect(first_count).to eq(1)
      expect(second_count).to eq(1)
    end

    it "caches exists? results" do
      created = Project.create!(tenant_id: 1, name: "Alpha")

      first_exists = Project.where(id: created.id, tenant_id: 1).exists?
      Project.where(id: created.id).delete_all
      second_exists = Project.where(id: created.id, tenant_id: 1).exists?

      expect(first_exists).to be(true)
      expect(second_exists).to be(true)
    end
  end

  describe "cache invalidation by version change" do
    it "invalidates load cache after tenant version bump" do
      Project.create!(tenant_id: 1, name: "Alpha")
      Project.where(tenant_id: 1).load

      Project.create!(tenant_id: 1, name: "Beta")

      reloaded = Project.where(tenant_id: 1).load
      expect(reloaded.map(&:name)).to contain_exactly("Alpha", "Beta")
    end
  end
end
