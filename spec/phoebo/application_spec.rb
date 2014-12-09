require_relative '../spec_helper'

describe Phoebo::Application do

  # Set output stream before test
  before(:all) {
    described_class.stdout = StringIO.new
    described_class.stderr = StringIO.new
  }

  # Clean output streams before each run
  before(:each) {
    described_class.stdout.truncate(0)
    described_class.stderr.truncate(0)
  }

  context 'general' do
    subject(:app) { described_class.new }

    it 'is runnable' do
      expect(app.respond_to?(:run)).to eq true
    end
  end

  context '--version argument' do
    subject(:app) { described_class.new(['--version']) }

    it 'returns 0' do
      expect(app.run).to eq 0
    end

    it 'shows version' do
      app.run
      expect(app.stdout.string).to include(Phoebo::VERSION)
    end
  end

end