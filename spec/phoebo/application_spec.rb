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

    it 'holds instance' do
      app
      expect(described_class.instance.is_a?(described_class)).to be true
    end

    it 'creates Environment' do
      expect(app.environment.is_a?(Phoebo::Environment)).to be true
    end

    it 'creates TemporaryFileManager' do
      expect(app.temp_file_manager.is_a?(Phoebo::Util::TempFileManager)).to be true
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

  context '--help argument' do
    subject(:app) { described_class.new(['--help']) }

    it 'returns 0' do
      expect(app.run).to eq 0
    end

    it 'shows usage' do
      app.run
      expect(app.stdout.string).to include('Usage:')
    end
  end

  context 'normal run with all arguments' do
    let(:args) {[
       '--repository', 'ssh://host/path/to/repo.git',
       '--ssh-user', 'git',
       '--ssh-key', './key',
       '--ssh-public', './key.pub',
       '--docker-user', 'joe',
       '--docker-password', 'secret123',
       '--docker-email', 'joe@domain.tld',
       'dir1', 'dir2'
    ]}

    subject(:app) { described_class.new(args) }

    it 'returns 1 if no files were processed' do
      allow(Phoebo::Git).to receive(:clone).and_return(nil)
      expect(app.run).to eq 1
    end
  end

  context 'bad arguments' do
    subject(:app) { described_class.new(['--foobar']) }

    it 'returns 1' do
      expect(app.run).to eq 1
    end

    it 'shows usage' do
      app.run
      expect(app.stdout.string).to include('Usage:')
    end
  end

end