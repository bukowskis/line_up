require 'spec_helper'

describe LineUp do

  let(:logger)      { mock(:logger) }

  let(:lineup) { LineUp }

  describe '.config' do
    before do
      LineUp.reset!
    end

    it 'is an STDOUT logger' do
      Logger.should_receive(:new).with(STDOUT).and_return logger
      lineup.config.logger.should be logger
    end

    context 'with Rails' do
      before do
        ensure_module :Rails
        Rails.stub!(:logger).and_return(logger)
      end

      after do
        Object.send(:remove_const, :Rails)
      end

      it 'is the Rails logger' do
        lineup.config.logger.should be Rails.logger
      end
    end
  end
end
