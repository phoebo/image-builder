require_relative '../spec_helper'

describe Phoebo::Environment do
  before(:all) {
    @path = [
      "#{File::SEPARATOR}a",
      "#{File::SEPARATOR}b",
      "#{File::SEPARATOR}c"
    ]
  }

  subject(:env) {
    described_class.new({'PATH' => @path.join(File::PATH_SEPARATOR) })
  }

  context 'path lookup' do
    it 'looks up path' do
      allow(File).to receive(:executable?).with("#{@path[0]}#{File::SEPARATOR}bash").and_return(false)
      allow(File).to receive(:executable?).with("#{@path[1]}#{File::SEPARATOR}bash").and_return(true)
      allow(File).to receive(:executable?).with("#{@path[2]}#{File::SEPARATOR}bash").and_return(true)
      expect(env.bash_path).to eq "#{@path[1]}#{File::SEPARATOR}bash"
    end

    it 'nil if not found' do
      @path.each { |path|
        allow(File).to receive(:executable?).with("#{path}#{File::SEPARATOR}git").and_return(false)
      }
      expect(env.git_path).to eq nil
    end
  end
end
