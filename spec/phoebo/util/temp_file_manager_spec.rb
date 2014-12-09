require_relative '../../spec_helper'

describe Phoebo::Util::TempFileManager, :order => :defined do
    before (:all) {
      @manager = described_class.new("#{File::SEPARATOR}tmp")
    }

    it 'does not need clean-up at init' do
      expect(@manager.need_cleanup?).to eq false
    end
    # ->
    it 'creates path' do
      @manager.path 'a', 'b'
    end
    # ->
    it 'does need to clean-up' do
      expect(@manager.need_cleanup?).to eq true
    end
    # ->
    it 'cleans up' do
      @manager.cleanup
    end
end