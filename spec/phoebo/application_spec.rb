require_relative '../spec_helper'

describe Phoebo::Application do
  subject(:app) {
    app = described_class.new
    app.stdout = StringIO.new
    app.stderr = StringIO.new
    app
  }

  it 'is runnable' do
    expect(app.respond_to?(:run)).to eq true
  end

  context '--version argument' do
    subject(:app) {
      app = described_class.new(['--version'])
      app.stdout = StringIO.new
      app.stderr = StringIO.new
      app
    }

    it 'returns 0' do
      expect(app.run).to eq 0
    end

    it 'shows version' do
      expect(app.stdout.string).to include(Phoebo::VERSION)
    end
  end

end