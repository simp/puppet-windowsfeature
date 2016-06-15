require 'spec_helper'

provider_class = Puppet::Type.type(:windowsfeature).provider(:default)

describe provider_class do
  let :resource do
    Puppet::Type.type(:windowsfeature).new(
      title: 'feature-name',
      provider: described_class.name
  )
  end

  let(:provider) { resource.provider }

  let(:instance) { provider.class.instances.first }

  let(:windows_feature_json) do
    # Read big JSON file from a base 2012R2 run
    fixture('windows-features')
  end

  before :each do
    Facter.stubs(:value).with(:kernel).returns(:windows)
    provider.class.stubs(:ps).with('Get-WindowsFeature | ConvertTo-JSON').returns(windows_feature_json)
  end

  it 'supports resource discovery' do
    expect(provider_class).to respond_to(:instances)
  end

  it 'supports resource prefetching' do
    expect(provider_class).to respond_to(:prefetch)
  end

  it 'is ensurable' do
    provider.feature?(:ensurable)
  end

  [:exists?, :create, :destroy].each do |method|
    it "has a(n) #{method} method" do
      expect(provider).to respond_to(method)
    end
  end

  describe 'self.prefetch' do
    it 'exists' do
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe 'self.instances' do
    it 'returns an array of windows features' do
      features = provider.class.instances.map(&:name)
      expect(features).to include('ad-certificate', 'fileandstorage-services')
    end
  end

  describe 'create' do
    context 'on Windows 6.1' do
      it 'runs Import-Module ServerManager; Add-WindowsFeature' do
        Facter.expects(:value).with(:kernelmajversion).returns('6.1')
        Puppet::Type::Windowsfeature::ProviderDefault.expects('ps').with('Import-Module ServerManager; Add-WindowsFeature', 'feature-name').returns('')
        provider.create
      end
    end
    context 'on Windows 6.2 onward' do
      it 'runs Install-WindowsFeature' do
        Facter.expects(:value).with(:kernelmajversion).returns('6.2')
        Puppet::Type::Windowsfeature::ProviderDefault.expects('ps').with('Install-WindowsFeature', 'feature-name').returns('')
        provider.create
      end
    end
  end

  describe 'destroy' do
    context 'on Windows 6.1' do
      it 'runs Import-Module ServerManager; Add-WindowsFeature' do
        Facter.expects(:value).with(:kernelmajversion).returns('6.1')
        Puppet::Type::Windowsfeature::ProviderDefault.expects('ps').with('Import-Module ServerManager; Remove-WindowsFeature', 'feature-name').returns('')
        provider.destroy
      end
    end
    context 'on Windows 6.2 onward' do
      it 'runs Install-WindowsFeature' do
        Facter.expects(:value).with(:kernelmajversion).returns('6.2')
        Puppet::Type::Windowsfeature::ProviderDefault.expects('ps').with('Remove-WindowsFeature', 'feature-name').returns('')
        provider.destroy
      end
    end
  end
end