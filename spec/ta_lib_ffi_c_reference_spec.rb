# frozen_string_literal: true

require "spec_helper"
require_relative "support/c_reference"

RSpec.describe TALibFFI do
  functions = CReference.functions

  # Keep the expected Ruby keys independent of the binding's name conversion.
  let(:output_keys) do
    {
      "ACCBANDS" => %i[upper_band middle_band lower_band],
      "AROON" => %i[aroon_down aroon_up],
      "BBANDS" => %i[upper_band middle_band lower_band],
      "HT_PHASOR" => %i[in_phase quadrature],
      "HT_SINE" => %i[sine lead_sine],
      "MACD" => %i[macd macd_signal macd_hist],
      "MACDEXT" => %i[macd macd_signal macd_hist],
      "MACDFIX" => %i[macd macd_signal macd_hist],
      "MAMA" => %i[mama fama],
      "MINMAX" => %i[min max],
      "MINMAXINDEX" => %i[min_idx max_idx],
      "STOCH" => %i[slow_k slow_d],
      "STOCHF" => %i[fast_k fast_d],
      "STOCHRSI" => %i[fast_k fast_d]
    }
  end

  let(:series) do
    # Enough history for default lookbacks. Keep real inputs in (0, 1) so
    # ACOS, ASIN, LOG10 and SQRT all produce finite, comparable results.
    close = Array.new(128) { |i| (40 + (7 * i % 23) + (i % 13 - 6).abs) / 100.0 }
    open = close.map.with_index { |price, i| price + (i % 7 - 3) / 100.0 }
    {
      "Open" => open, "Close" => close,
      "High" => open.zip(close).map { |bar| bar.max + 0.02 },
      "Low" => open.zip(close).map { |bar| bar.min - 0.015 },
      "Volume" => Array.new(close.size) { |i| 1000 + (i * 37 % 137) },
      "inReal" => close, "inReal0" => close, "inReal1" => open,
      "inPeriods" => Array.new(close.size) { |i| 2.0 + (i % 7) }
    }
  end

  def c_result(function, data, options = function.defaults, empty: false)
    outputs = function.call(data, options)
    expect(outputs.first.empty?).to eq(empty), "TA_#{function.name} returned #{outputs.first.size} values"
    return outputs.first if outputs.one?

    # transpose requires exactly one Ruby key per positional C output.
    [output_keys.fetch(function.name), outputs].transpose.to_h
  end

  def ruby_result(function, data, keywords = {})
    described_class.public_send(function.name.downcase, *function.ruby_inputs(data), **keywords)
  end

  it "covers every indicator in the native function tables" do
    names = described_class.group_table.flat_map { |group| described_class.function_table(group) }
    expect(functions.keys).to match_array(names)
  end

  # Both calls use the same binary and identical doubles. eql also checks
  # numeric types, the exact array length and every key of a multi-output result.
  functions.each_value do |function|
    it ".#{function.name.downcase} matches TA_#{function.name} with its default parameters" do
      expected = c_result(function, series)
      expect(ruby_result(function, series)).to eql(expected)
    end
  end

  # Native options are positional, independent of how Ruby maps keyword names.
  {
    "SMA" => [{ time_period: 5 }, [5]],
    "TEMA" => [{ time_period: 5 }, [5]],
    "TRIMA" => [{ time_period: 5 }, [5]],
    "WMA" => [{ time_period: 5 }, [5]],
    "T3" => [{ time_period: 4, v_factor: 0.35 }, [4, 0.35]],
    "SAREXT" => [{ offset_on_reverse: 0.1, acceleration_short: 0.07 }, [0.0, 0.1, 0.02, 0.02, 0.2, 0.02, 0.07, 0.2]],
    "BBANDS" => [{ ma_type: 1, nb_dev_dn: 1.5, nb_dev_up: 2.5, time_period: 7 }, [7, 2.5, 1.5, 1]]
  }.each do |name, (keywords, arguments)|
    function = functions.fetch(name)

    describe ".#{name.downcase} with custom parameters" do
      it "matches every C output on varying prices" do
        expected = c_result(function, series, arguments)
        expect(ruby_result(function, series, keywords)).to eql(expected)
      end

      it "matches every C output on constant prices" do
        constant = series.transform_values { |values| Array.new(values.size, values.first) }
        expected = c_result(function, constant, arguments)
        expect(ruby_result(function, constant, keywords)).to eql(expected)
      end

      it "returns the C output shape with one bar of history" do
        short = series.transform_values { |values| values.first(1) }
        expected = c_result(function, short, arguments, empty: true)
        expect(ruby_result(function, short, keywords)).to eql(expected)
      end
    end
  end
end
