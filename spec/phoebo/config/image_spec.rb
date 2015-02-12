require_relative '../../spec_helper'

describe Phoebo::Config::Image do

  let(:dsl) {
    Proc.new {
      add('.', '/app/')
      run('composer', 'install', '--prefer-dist')
    }
  }

  subject { described_class.new('image-name', 'base-image-name') }

  it 'processes commands' do
    expect(Phoebo::Config::ImageCommands::Add).to receive(:action).with('.', '/app/')
    expect(Phoebo::Config::ImageCommands::Run).to receive(:action).with('composer', 'install', '--prefer-dist')
    subject.dsl_eval(dsl)
  end
end