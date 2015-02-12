require_relative '../spec_helper'

describe Phoebo::Worker do

  let(:path) { './somepath' }
  let(:request) {
    image = instance_double(Phoebo::Request)
  }

  let(:config) {
    config = instance_double(Phoebo::Config)
    allow(config).to receive(:images).and_return([])
    config
  }

  subject { described_class.new(request) }

  context 'Pheobofile' do
    before(:each) do
      allow(File).to receive(:exists?).and_return(true)
      allow(Phoebo::Config).to receive(:new_from_file).and_return(config)
    end

    it 'processes directories' do
      subject.process(path)
    end
  end


end