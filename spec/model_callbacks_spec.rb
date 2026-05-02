# frozen_string_literal: true

RSpec.describe SmartCacheTenant::ModelCallbacks do
  describe "after_commit invalidation" do
    it "invalidates cache for the same tenant" do
      Project.create!(tenant_id: 1, name: "Alpha")
      Project.where(tenant_id: 1).load

      Project.create!(tenant_id: 1, name: "Beta")

      records = Project.where(tenant_id: 1).load
      expect(records.map(&:name)).to contain_exactly("Alpha", "Beta")
    end

    it "does not invalidate other tenant caches" do
      tenant_1 = Project.create!(tenant_id: 1, name: "T1")
      tenant_2 = Project.create!(tenant_id: 2, name: "T2")

      Project.where(tenant_id: 1).load
      Project.where(tenant_id: 2).load

      Project.where(id: tenant_2.id).delete_all
      Project.create!(tenant_id: 1, name: "T1-new")

      tenant_2_records = Project.where(tenant_id: 2).load
      expect(tenant_2_records.map(&:id)).to eq([tenant_2.id])
      expect(tenant_1.id).to be_present
    end
  end
end
