require_relative '../spec_helper'

describe Phoebo::Console do
  before {
    @sample_class = Class.new do
      include Phoebo::Console
    end
  }

  context 'default streams' do
    subject {
      @sample_class.new
    }

    it 'stdout returns io' do
      expect(subject.stdout.is_a?(IO)).to eq true
    end

    it 'stderr returns io' do
      expect(subject.stderr.is_a?(IO)).to eq true
    end
  end

  context 'streams set for class' do
    subject {
      sample_class = @sample_class.dup
      sample_class.stdout = StringIO.new
      sample_class.stderr = StringIO.new
      sample_class.new
    }

    it 'does not effect default streams' do
      expect(subject.stdout).not_to be @sample_class.stdout
      expect(subject.stderr).not_to be @sample_class.stderr
    end

    it 'stdout returns class default' do
      expect(subject.stdout.is_a?(StringIO)).to eq true
      expect(subject.stdout).to be subject.class.stdout
    end

    it 'stderr returns class default' do
      expect(subject.stderr.is_a?(StringIO)).to eq true
      expect(subject.stderr).to be subject.class.stderr
    end

    it 'stdout != stderr' do
      expect(subject.stdout).not_to be subject.stderr
    end
  end

  context 'streams set for instance' do
    subject {
      sample_class = @sample_class.dup
      sample_class.stdout = StringIO.new
      sample_class.stderr = StringIO.new

      subject = sample_class.new
      subject.stdout = StringIO.new
      subject.stderr = StringIO.new

      subject
    }

    it 'stdout returns set io' do
      expect(subject.stdout.is_a?(StringIO)).to eq true
      expect(subject.stdout).not_to be subject.class.stdout
    end

    it 'stderr returns set io' do
      expect(subject.stderr.is_a?(StringIO)).to eq true
      expect(subject.stderr).not_to be subject.class.stderr
    end

    it 'stdout != stderr' do
      expect(subject.stdout).not_to be subject.stderr
    end
  end

end