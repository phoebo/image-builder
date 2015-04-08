require_relative '../spec_helper'

describe Phoebo::Config do

  subject { described_class }

  context 'loading DSL' do
    subject { described_class }

    let(:dsl_content) { Proc.new { } }

    it 'loads block' do
      allow(Kernel).to receive(:load).with('./Phoebofile', true) do
        Phoebo.configure(1, &dsl_content)
      end

      # It goes like this:
      # 1) Config.new_from_file('./Phoebofile')
      # 2) It loads file using Kernel.load (immediatly interprets it's content)
      # 3) Inside of this file there is call Phoebo.configure(version) { DSL BLOCK }
      #    which introduces our DSL.
      # 4) When Phoebo.configure() is called it passes DSL BLOCK to Config.new_from_block()
      # 5) Config.new_from_block() saves instance internally
      # 6) Config.new_from_file() returns saved instance

      expect(subject).to receive(:new_from_block).with(dsl_content).and_call_original
      expect(subject.new_from_file('./Phoebofile').is_a?(described_class)).to eq true
    end

    it 'raises human readable message on syntax error' do
      allow(Kernel).to receive(:load).with('./Phoebofile', true) do
        raise ::SyntaxError
      end

      expect { subject.new_from_file('./Phoebofile') }.to raise_error(Phoebo::SyntaxError)
    end
  end

  context 'images' do
    subject { described_class.new }
    let(:image_dsl_block) { Proc.new { } }
    let(:dsl) {
      child_block = image_dsl_block
      Proc.new {
        image('image-name', from: 'base-image-name', &child_block)
      }
    }

    it 'processes images' do
      image = instance_double(Phoebo::Config::Image)
      expect(Phoebo::Config::Image).to receive(:new).with('image-name', { from: 'base-image-name' }, image_dsl_block).and_return(image)

      subject.dsl_eval(dsl)
      expect(subject.images).to include(image)
    end
  end
end