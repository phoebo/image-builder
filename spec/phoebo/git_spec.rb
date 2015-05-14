require_relative '../spec_helper'

describe Phoebo::Git, skip: Phoebo::Git.available? ? false : "No Git implementation installed" do

  subject { described_class }

  context 'without credentials' do
    let(:request) do
      Phoebo::Request.new do
        repo_url = 'ssh://somehost.tld/user/repo.git'
        ssh_private_file = 'key'
        ssh_public_file = 'key.pub'
      end
    end

    it 'clones' do
      expect(Rugged::Repository).to receive(:clone_at)
      subject.clone(request, '/tmp/somepath')
    end
  end

  context 'with SSH credentials' do
    let(:request) do
      Phoebo::Request.new do
        repo_url = 'ssh://somehost.tld/user/repo.git'
      end
    end

    it 'clones' do
      expect(Rugged::Repository).to receive(:clone_at)
      subject.clone(request, '/tmp/somepath')
    end
  end

end