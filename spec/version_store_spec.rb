# frozen_string_literal: true

RSpec.describe SmartCacheTenant::VersionStore do
  describe ".build_key" do
    it "builds a tenant-scoped key when tenant_id is present" do
      key = described_class.build_key(Project, 10)

      expect(key).to include("smart_cache:table_version:projects")
      expect(key).to end_with("tenant_id:10")
    end

    it "builds a model key without tenant suffix when tenant_id is blank" do
      key = described_class.build_key(Project)

      expect(key).to include("smart_cache:table_version:projects")
      expect(key).not_to include("tenant_id:")
    end
  end

  describe ".current" do
    it "returns the same version while cache entry exists" do
      first = described_class.current(Project, 1)
      second = described_class.current(Project, 1)

      expect(second).to eq(first)
    end
  end

  describe ".bump!" do
    it "updates only the provided tenant version key" do
      key_tenant_1 = described_class.build_key(Project, 1)
      key_tenant_2 = described_class.build_key(Project, 2)

      Rails.cache.write(key_tenant_1, "v1-old", expires_in: 1.hour)
      Rails.cache.write(key_tenant_2, "v2-old", expires_in: 1.hour)
      allow(described_class).to receive(:generate_version).and_return("v1-new")

      described_class.bump!(Project, 1)

      expect(Rails.cache.read(key_tenant_1)).to eq("v1-new")
      expect(Rails.cache.read(key_tenant_2)).to eq("v2-old")
    end

    it "invalidates all tenant version keys when tenant_id is blank" do
      key_tenant_1 = described_class.build_key(Project, 1)
      key_tenant_2 = described_class.build_key(Project, 2)

      Rails.cache.write(key_tenant_1, "v1", expires_in: 1.hour)
      Rails.cache.write(key_tenant_2, "v2", expires_in: 1.hour)

      described_class.bump!(Project)

      expect(Rails.cache.read(key_tenant_1)).to be_nil
      expect(Rails.cache.read(key_tenant_2)).to be_nil
    end
  end
end
