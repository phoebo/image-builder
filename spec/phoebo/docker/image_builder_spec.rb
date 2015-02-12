require_relative '../../spec_helper'

describe Phoebo::Docker::ImageBuilder do

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

  subject { described_class.new('./somedir') }

  let(:image) {
    actions = [
      Phoebo::Config::ImageCommands::Add.action('.', '/app/'),
      Phoebo::Config::ImageCommands::Run.action('composer', 'install', '--prefer-dist')
    ]

    image = instance_double(Phoebo::Config::Image)
    allow(image).to receive(:name).and_return('image-name')
    allow(image).to receive(:from).and_return('debian')
    allow(image).to receive(:actions).and_return(actions)

    image
  }

  let(:docker_image) {
    image = instance_double(Docker::Image)
    allow(image).to receive(:id).and_return('c90d655b99b2')
    allow(image).to receive(:tag).and_return(image)
    allow(image).to receive(:json).and_return({'VirtualSize' => 123, 'Size' => 123})
    image
  }

  it 'processes commands' do
    expect(Docker::Image).to receive(:build_from_tar).and_return(docker_image)
    subject.build(image)
  end
end