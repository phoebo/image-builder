require_relative '../spec_helper'

describe Phoebo::Request do

  subject { described_class.new }

  context 'request validation' do
    it 'defaults are valid' do
      expect(subject.errors).to be_empty
    end

    # Unix like format is not accepted and should produce human-readable message
    it 'returns error on invalid repo URL' do
      subject.repo_url = '@host:a.git'
      expect(subject.errors.select { |e| e.include?('Invalid repository URL.') }).not_to be_empty
    end

    # Non SSH repos not supported at the moment
    it 'returns error when non SSH repo is requested' do
      subject.repo_url = 'http://host/repo.git'
      expect(subject.errors.select { |e| e.include?('Invalid repository URL.') }).not_to be_empty
    end

    it 'returns error on invalid ping URL' do
      subject.ping_url = '@host:a.git'
      expect(subject.errors.select { |e| e.include?('Invalid ping URL.') }).not_to be_empty
    end

    it 'valid repo url returns no errors' do
      subject.repo_url = 'ssh://host/path/to/repo.git'
      expect(subject.errors.select { |e| e.include?('Invalid repository URL.') }).to be_empty
    end

    it 'validates private SSH key if required' do
      subject.ssh_public_file = 'secret.pub'
      expect(subject.errors.select { |e| e.include?('private') && e.include?('SSH') }).not_to be_empty
    end

    it 'validates public SSH key  if required' do
      subject.ssh_private_file = 'secret'
      expect(subject.errors.select { |e| e.include?('public') && e.include?('SSH') }).not_to be_empty
    end

    it 'no error with both SSH keys valid' do
      subject.repo_url = 'ssh://host/path/to/repo.git'
      subject.ssh_private_file = 'secret'
      subject.ssh_public_file = 'secret.pub'
      expect(subject.errors.select { |e| e.include?('SSH') }).to be_empty
    end

    it 'enforces none or all docker parameters' do
      subject.docker_user = 'user'
      expect(subject.errors.select { |e| e.include?('Docker') }.size).to be 2
      subject.docker_password = 'password'
      expect(subject.errors.select { |e| e.include?('Docker') }.size).to be 1
      subject.docker_email = 'email'
      expect(subject.errors.select { |e| e.include?('Docker') }).to be_empty
    end

    it 'raises exception' do
      subject.repo_url = '@host:a.git'
      expect { subject.validate }.to raise_error(Phoebo::InvalidRequestError)
    end
  end

  context 'loading from hash' do
    let(:valid_hash) do
      {
        ssh_private_file: 'secret',
        ssh_public_file: 'secret.pub'
      }
    end

    it 'raises error on unknown argument' do
      expect { subject.load_from_hash!({ a: 13 }) }.to raise_error(Phoebo::InvalidRequestError)
    end

    it 'applies arguments' do
      expect(subject.load_from_hash!(valid_hash).is_a?(described_class)).to eq true
      expect(subject.ssh_private_file).to be valid_hash[:ssh_private_file]
      expect(subject.ssh_public_file).to be valid_hash[:ssh_public_file]
    end
  end

  let(:json) do
    <<-EOS
    {
      "repo_url": "ssh://somehost.tld/user/repo.git"
    }
    EOS
  end

  let(:malformed_json) do
    <<-EOS
    {
      "repo_url
    }
    EOS
  end

  context 'loading from JSON' do
    it 'raises error on malformed data' do
      expect { subject.load_from_json!(malformed_json) }.to raise_error(Phoebo::InvalidRequestError)
    end

    it 'applies arguments' do
      subject.load_from_json!(json)
      expect(subject.repo_url).to eql('ssh://somehost.tld/user/repo.git')
    end
  end

  context 'loading from file' do
    it 'raises error if file does not exist' do
      allow(File).to receive(:exist?).and_return(false)
      expect { subject.load_from_file!('somefile.json') }.to raise_error(Phoebo::IOError)
    end

    it 'loads data' do
      allow(File).to receive(:exist?).and_return(true)
      allow(IO).to receive(:read).and_return(json)
      expect(subject).to receive(:load_from_json!).with(json)
      subject.load_from_file!('somefile.json')
    end
  end

  # TODO: cover all possible states
  context 'loading from url' do
    let(:http_response) do
      response = double
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:body).and_return(json)
      response
    end

    it 'loads data' do
      allow(Net::HTTP).to receive(:start).and_return(http_response)
      expect(subject).to receive(:load_from_json!).with(json)
      subject.load_from_url!('http://test')
    end
  end
end