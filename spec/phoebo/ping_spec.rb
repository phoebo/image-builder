require_relative '../spec_helper'

describe Phoebo::Ping do

  subject { described_class }

  let(:request) do
    request = double(Phoebo::Request)
    allow(request).to receive(:id).and_return('2e2996fe8420')
    allow(request).to receive(:ping_url).and_return('http://domain.tld/api/notify')
    request
  end

  let(:configs) do
    tasks = [{
      name: 'test',
      image: 'someimage',
      cmd: ['do_something', '--with', 'that']
    }]

    configs = [ config = double(Phoebo::Config) ]
    allow(config).to receive(:tasks).and_return(tasks)
    configs
  end

  let(:http_response) do
    response = double
    allow(response).to receive(:code).and_return(200)
    response
  end

  it 'pings' do
    allow(Net::HTTP).to receive(:start).and_return(http_response)
    subject.send(request, configs)
  end

end