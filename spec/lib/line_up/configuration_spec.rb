require 'spec_helper'

describe LineUp do

  let(:rails)  { Module.new }
  let(:logger) { double(:logger) }
  let(:lineup) { LineUp }

  describe '.config' do
    before do
      LineUp.reset!
    end

    it 'is an STDOUT logger' do
      expect(Logger).to receive(:new).with(STDOUT).and_return logger
      expect(lineup.config.logger).to eq(logger)
    end

    context 'with Rails' do
      before do
        allow(rails).to receive(:logger).and_return(logger)
        stub_const("Rails", rails)
      end

      it 'is the Rails logger' do
        expect(lineup.config.logger).to eq(Rails.logger)
      end
    end
  end
end
