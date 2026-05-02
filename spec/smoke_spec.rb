# frozen_string_literal: true

RSpec.describe SmartCacheTenant do
  it "loads and configures tenant cache support" do
    expect(SmartCacheTenant.config.enabled).to be(true)
    expect(SmartCacheTenant.config.tenant_column).to eq(:tenant_id)
  end

  it "can persist and query a cache-enabled model" do
    Project.create!(tenant_id: 1, name: "Alpha")

    records = Project.where(tenant_id: 1).load

    expect(records.size).to eq(1)
    expect(records.first.name).to eq("Alpha")
  end

  it "invalidates tenant-scoped version keys when bumping without tenant_id" do
    key_tenant_1 = SmartCacheTenant::VersionStore.build_key(Project, 1)
    key_tenant_2 = SmartCacheTenant::VersionStore.build_key(Project, 2)

    Rails.cache.write(key_tenant_1, "v1", expires_in: 1.hour)
    Rails.cache.write(key_tenant_2, "v2", expires_in: 1.hour)

    SmartCacheTenant::VersionStore.bump!(Project)

    expect(Rails.cache.read(key_tenant_1)).to be_nil
    expect(Rails.cache.read(key_tenant_2)).to be_nil
  end
end
