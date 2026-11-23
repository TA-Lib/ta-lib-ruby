# frozen_string_literal: true

require "spec_helper"
require "open3"

RSpec.describe TALibFFI do
  let(:prices) { [1.0, 2.0, 3.0, 4.0] }

  describe ".atr" do
    it "shows how to group high, low and close when given separate positional arguments" do
      expect { described_class.atr(prices, prices, prices) }
        .to raise_error(described_class::TALibError, /TALibFFI\.atr\(\[high, low, close\]\)/)
    end

    it "requires each component of the price group" do
      expect { described_class.atr([prices, prices]) }
        .to raise_error(described_class::TALibError, /\[high, low, close\]/)
    end

    it "validates the length of every series inside a price group" do
      expect { described_class.atr([prices, prices.first(2), prices]) }
        .to raise_error(described_class::TALibError, /equal lengths/)
      expect { described_class.atr([[], [], []]) }
        .to raise_error(described_class::TALibError, /empty/)
    end

    it "checks the values inside a price group" do
      expect { described_class.atr([prices, prices, [1, 2, nil, 4]]) }
        .to raise_error(described_class::TALibError, /numbers/)
    end
  end

  describe ".add" do
    it "validates the number and lengths of independent input arrays" do
      expect { described_class.add(prices) }.to raise_error(described_class::TALibError, /TALibFFI\.add/)
      expect { described_class.add(prices, prices.first(2)) }.to raise_error(described_class::TALibError, /equal lengths/)
    end
  end

  describe ".sma" do
    it "reports an unknown keyword and the accepted spelling" do
      expect { described_class.sma(prices, timeperiod: 2) }
        .to raise_error(described_class::TALibError, /SMA.*timeperiod.*time_period/)
    end

    it "identifies the keyword for invalid numeric parameters" do
      expect { described_class.sma(prices, time_period: "2") }
        .to raise_error(described_class::TALibError, /SMA.*time_period.*number/)
      expect { described_class.sma(prices, time_period: -1) }
        .to raise_error(described_class::TALibError, /SMA.*time_period=-1/)
    end
  end

  describe ".ema" do
    it "keeps resident memory bounded across repeated calls", if: File.readable?("/proc/self/status") do
      script = File.expand_path("support/ema_memory.rb", __dir__)
      growth, status = Open3.capture2(RbConfig.ruby, "-I", File.expand_path("../lib", __dir__), script)
      expect(status).to be_success
      # Leaking the input and output of each measured call consumes 32 MiB.
      expect(Integer(growth)).to be < 16 * 1024
    end
  end

  describe ".call_func" do
    it "can reuse a frozen argument list with a trailing options hash" do
      args = [prices, { time_period: 2 }.freeze].freeze
      2.times { expect(described_class.call_func("SMA", args)).to eq([1.5, 2.5, 3.5]) }
    end

    it "keeps mixed price and real inputs alive through garbage collection" do
      allow(described_class).to receive(:TA_CallFunc).and_wrap_original do |call, *args|
        GC.compact
        call.call(*args)
      end
      expect(described_class.obv([3, 1, 2], [[20, 10, 40]])).to eq([20.0, 10.0, 50.0])
    end

    it "releases the native holder after a failure during output setup" do
      allow(described_class).to receive(:TA_ParamHolderFree).and_call_original
      allow(described_class).to receive(:TA_SetOutputParamRealPtr).and_return(described_class::TA_BAD_PARAM)
      expect { described_class.sma(prices, time_period: 2) }.to raise_error(described_class::TALibError)
      expect(described_class).to have_received(:TA_ParamHolderFree).once
    end
  end

  describe ".prepare_double_array" do
    it "rejects a packed input whose length changed after validation" do
      expect { described_class.prepare_double_array(prices.first(2), size: 4) }
        .to raise_error(described_class::TALibError, /length changed/)
    end
  end

  describe ".prepare_integer_array" do
    it "packs signed values at the native integer width" do
      buffer = described_class.prepare_integer_array([-3, 0, 15], size: 3)
      expect(buffer.to_str.unpack("i!*")).to eql([-3, 0, 15])
    end
  end
end
