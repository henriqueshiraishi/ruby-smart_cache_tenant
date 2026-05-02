# frozen_string_literal: true

RSpec.describe "Bulk write invalidation" do
  describe "insert_all" do
    it "invalidates tenant cache when payload has tenant_id" do
      Project.create!(tenant_id: 1, name: "Alpha")
      Project.where(tenant_id: 1).load

      Project.insert_all([{ tenant_id: 1, name: "Beta", created_at: Time.current, updated_at: Time.current }])

      records = Project.where(tenant_id: 1).load
      expect(records.map(&:name)).to contain_exactly("Alpha", "Beta")
    end

    it "invalidates all tenant version keys when payload has no tenant_id" do
      key_tenant_1 = SmartCacheTenant::VersionStore.build_key(Project, 1)
      key_tenant_2 = SmartCacheTenant::VersionStore.build_key(Project, 2)

      Rails.cache.write(key_tenant_1, "v1", expires_in: 1.hour)
      Rails.cache.write(key_tenant_2, "v2", expires_in: 1.hour)

      Project.insert_all([{ name: "Global", created_at: Time.current, updated_at: Time.current }])

      expect(Rails.cache.read(key_tenant_1)).to be_nil
      expect(Rails.cache.read(key_tenant_2)).to be_nil
    end
  end

  describe "upsert_all" do
    it "bumps tenant version for upserted tenant" do
      project = Project.create!(tenant_id: 1, name: "Alpha")
      version_key = SmartCacheTenant::VersionStore.build_key(Project, 1)

      Rails.cache.write(version_key, "v1-old", expires_in: 1.hour)
      allow(SmartCacheTenant::VersionStore).to receive(:generate_version).and_return("v1-new")

      Project.upsert_all([
        { id: project.id, tenant_id: 1, name: "Alpha-updated", created_at: project.created_at, updated_at: Time.current }
      ])

      expect(Rails.cache.read(version_key)).to eq("v1-new")
    end
  end

  describe "update_all" do
    it "invalidates cache from relation bulk updates" do
      Project.create!(tenant_id: 1, name: "Alpha")
      Project.where(tenant_id: 1).load

      Project.where(tenant_id: 1).update_all(name: "Bulk-updated")

      names = Project.where(tenant_id: 1).load.map(&:name)
      expect(names).to eq(["Bulk-updated"])
    end
  end
end
