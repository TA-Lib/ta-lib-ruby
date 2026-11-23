# frozen_string_literal: true

require "spec_helper"

RSpec.describe TALibFFI do
  shared_examples "ta_lib_input_validation" do |method_name|
    context "when input is invalid" do
      it "raises error for empty array" do
        expect { described_class.public_send(method_name, []) }
          .to raise_error(described_class::TALibError)
      end

      it "raises error for nil input" do
        expect { described_class.public_send(method_name, nil) }
          .to raise_error(described_class::TALibError)
      end

      it "raises error for non-numeric values" do
        expect { described_class.public_send(method_name, [1.0, "invalid", 3.0]) }
          .to raise_error(described_class::TALibError)
      end
    end
  end

  describe "Version and Initialization" do
    it "has a version number" do
      expect(described_class::VERSION).to eq("0.3.0")
    end
  end

  describe "Math Operators" do
    let(:price_series) { [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0] }
    let(:first_price_set) { [1.0, 2.0, 3.0, 4.0, 5.0] }
    let(:second_price_set) { [2.0, 2.0, 3.0, 5.0, 5.0] }

    describe "#add" do
      it "performs vector arithmetic addition of two arrays" do
        result = described_class.add(first_price_set, second_price_set)
        expect(result).to eq([3.0, 4.0, 6.0, 9.0, 10.0])
      end

      it "returns array of same length as inputs" do
        result = described_class.add(first_price_set, second_price_set)
        expect(result.length).to eq(first_price_set.length)
      end

      it "handles floating point arithmetic properly" do
        array1 = [1.5, 2.5, 3.5]
        array2 = [0.5, 1.5, 2.5]
        result = described_class.add(array1, array2)
        expect(result).to eq([2.0, 4.0, 6.0])
      end
    end

    describe "#div" do
      it "performs vector arithmetic division of two arrays" do
        result = described_class.div(first_price_set, second_price_set)
        expect(result).to eq([0.5, 1.0, 1.0, 0.8, 1.0])
      end

      it "returns array of same length as inputs" do
        result = described_class.div(first_price_set, second_price_set)
        expect(result.length).to eq(first_price_set.length)
      end

      it "handles division by zero" do
        array1 = [1.0, 2.0, 3.0]
        array2 = [1.0, 0.0, 2.0]
        result = described_class.div(array1, array2)
        expect(result).to eq([1.0, Float::INFINITY, 1.5])
      end

      it "handles floating point division properly" do
        array1 = [3.0, 5.0, 7.0]
        array2 = [2.0, 2.0, 2.0]
        result = described_class.div(array1, array2)
        expect(result).to eq([1.5, 2.5, 3.5])
      end
    end

    describe "#max" do
      it "calculates highest value over default period (30)" do
        result = described_class.max((1..50).to_a)
        expect(result).to eq((30..50).to_a)
      end

      it "calculates highest value over specified period" do
        result = described_class.max(first_price_set, time_period: 3)
        expect(result).to eq([3.0, 4.0, 5.0])
      end

      it "returns empty array when time period is larger than data length" do
        result = described_class.max(first_price_set, time_period: first_price_set.length + 1)
        expect(result).to be_empty
      end

      it "raises error when time period is zero" do
        expect { described_class.max(first_price_set, time_period: 0) }.to raise_error(described_class::TALibError)
      end

      it "raises error when time period is negative" do
        expect { described_class.max(first_price_set, time_period: -1) }.to raise_error(described_class::TALibError)
      end

      it "handles floating point values properly" do
        data = [1.5, 2.5, 1.8, 2.2, 1.9]
        result = described_class.max(data, time_period: 3)
        expect(result.first).to eq(2.5)
      end

      it "correctly identifies maximum in descending series" do
        data = [5.0, 4.0, 3.0, 2.0, 1.0]
        result = described_class.max(data, time_period: 3)
        expect(result.first).to eq(5.0)
      end

      it "correctly identifies maximum in ascending series" do
        data = [1.0, 2.0, 3.0, 4.0, 5.0]
        result = described_class.max(data, time_period: 3)
        expect(result.first).to eq(3.0)
      end
    end

    describe "#maxindex" do
      let(:sample_data) { [1.0, 3.0, 2.0, 5.0, 4.0] }

      it "returns empty array when input length is less than default period (30)" do
        result = described_class.maxindex(sample_data)
        expect(result).to be_empty
      end

      it "calculates index of highest value over specified period" do
        result = described_class.maxindex(sample_data, time_period: 3)
        expect(result).to eq([1, 3, 3])
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.maxindex(sample_data, time_period: 6)
        expect(result).to be_empty
      end

      it_behaves_like "ta_lib_input_validation", :maxindex
    end

    describe "#min" do
      let(:sample_data) { [3.0, 1.0, 4.0, 2.0, 5.0] }
      let(:float_data) { [1.5, 2.7, 0.8, 3.2, 1.1] }

      it_behaves_like "ta_lib_input_validation", :min

      it "returns empty array when input length is less than default period (30)" do
        result = described_class.min(sample_data)
        expect(result).to be_empty
      end

      it "returns minimum values for specified time period" do
        result = described_class.min(sample_data, time_period: 3)
        expect(result).to eq([1.0, 1.0, 2.0])
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.min(sample_data, time_period: 6)
        expect(result).to be_empty
      end

      it "calculates correct minimum values with floating point numbers" do
        result = described_class.min(float_data, time_period: 2)
        expect(result).to eq([1.5, 0.8, 0.8, 1.1])
      end
    end

    describe "#minindex" do
      let(:sample_data) { [3.0, 1.0, 4.0, 2.0, 5.0] }

      it_behaves_like "ta_lib_input_validation", :minindex

      it "returns empty array when input length is less than default period (30)" do
        result = described_class.minindex(sample_data)
        expect(result).to be_empty
      end

      it "calculates index of lowest value over specified period" do
        result = described_class.minindex(sample_data, time_period: 3)
        expect(result).to eq([1, 1, 3])
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.minindex(sample_data, time_period: 6)
        expect(result).to be_empty
      end
    end

    describe "#minmax" do
      let(:sample_data) { [3.0, 1.0, 4.0, 2.0, 5.0] }

      it_behaves_like "ta_lib_input_validation", :minmax

      it "returns empty array when input length is less than default period (30)" do
        result = described_class.minmax(sample_data)
        expect(result[:min]).to be_empty
        expect(result[:max]).to be_empty
      end

      it "calculates min and max values over specified period" do
        result = described_class.minmax(sample_data, time_period: 3)
        expect(result[:min]).to eq([1.0, 1.0, 2.0])
        expect(result[:max]).to eq([4.0, 4.0, 5.0])
      end

      it "returns empty arrays when period exceeds data length" do
        result = described_class.minmax(sample_data, time_period: 6)
        expect(result[:min]).to be_empty
        expect(result[:max]).to be_empty
      end

      it "uses default time period of 30 when not specified" do
        result = described_class.minmax(Array.new(50, 1.0))
        expect(result[:min].length).to eq(21)
        expect(result[:max].length).to eq(21)
      end

      it "handles floating point numbers correctly" do
        data = [1.5, 2.7, 0.8, 3.2, 1.1]
        result = described_class.minmax(data, time_period: 2)
        expect(result[:min]).to eq([1.5, 0.8, 0.8, 1.1])
        expect(result[:max]).to eq([2.7, 2.7, 3.2, 3.2])
      end

      it "handles all same values" do
        data = [2.0, 2.0, 2.0, 2.0, 2.0]
        result = described_class.minmax(data, time_period: 3)
        expect(result[:min]).to eq([2.0, 2.0, 2.0])
        expect(result[:max]).to eq([2.0, 2.0, 2.0])
      end

      it "handles negative values" do
        data = [-1.0, -3.0, -2.0, -5.0, -4.0]
        result = described_class.minmax(data, time_period: 3)
        expect(result[:min]).to eq([-3.0, -5.0, -5.0])
        expect(result[:max]).to eq([-1.0, -2.0, -2.0])
      end

      it "handles mixed positive and negative values" do
        data = [-1.0, 2.0, -3.0, 4.0, -5.0]
        result = described_class.minmax(data, time_period: 3)
        expect(result[:min]).to eq([-3.0, -3.0, -5.0])
        expect(result[:max]).to eq([2.0, 4.0, 4.0])
      end

      it "raises error when time period is less than 2" do
        expect { described_class.minmax(sample_data, time_period: 1) }.to raise_error(described_class::TALibError)
      end

      it "raises error when time period is zero" do
        expect { described_class.minmax(sample_data, time_period: 0) }.to raise_error(described_class::TALibError)
      end

      it "raises error when time period is negative" do
        expect { described_class.minmax(sample_data, time_period: -1) }.to raise_error(described_class::TALibError)
      end
    end

    describe "#minmaxindex" do
      let(:sample_data) { [3.0, 1.0, 4.0, 2.0, 5.0] }

      it_behaves_like "ta_lib_input_validation", :minmaxindex

      it "returns empty arrays when input length is less than default period (30)" do
        result = described_class.minmaxindex(sample_data)
        expect(result[:min_idx]).to be_empty
        expect(result[:max_idx]).to be_empty
      end

      it "calculates indices over specified period" do
        result = described_class.minmaxindex(sample_data, time_period: 3)
        expect(result[:min_idx]).to eq([1, 1, 3])
        expect(result[:max_idx]).to eq([2, 2, 4])
      end

      it "returns empty arrays when period exceeds data length" do
        result = described_class.minmaxindex(sample_data, time_period: 6)
        expect(result[:min_idx]).to be_empty
        expect(result[:max_idx]).to be_empty
      end

      it "handles repeated values correctly" do
        data = [3.0, 1.0, 1.0, 2.0, 5.0]
        result = described_class.minmaxindex(data, time_period: 3)
        expect(result[:min_idx]).to eq([1, 1, 2])
        expect(result[:max_idx]).to eq([0, 3, 4])
      end

      it "handles all same values" do
        data = [2.0, 2.0, 2.0, 2.0, 2.0]
        result = described_class.minmaxindex(data, time_period: 3)
        expect(result[:min_idx]).to eq([0, 1, 2])
        expect(result[:max_idx]).to eq([0, 1, 2])
      end

      it "handles negative values" do
        data = [-1.0, -3.0, -2.0, -5.0, -4.0]
        result = described_class.minmaxindex(data, time_period: 3)
        expect(result[:min_idx]).to eq([1, 3, 3])
        expect(result[:max_idx]).to eq([0, 2, 2])
      end
    end

    describe "#mult" do
      it_behaves_like "ta_lib_input_validation", :mult

      it "multiplies two arrays element by element" do
        result = described_class.mult(first_price_set, second_price_set)
        expect(result).to eq([2.0, 4.0, 9.0, 20.0, 25.0])
      end

      it "handles floating point multiplication" do
        array1 = [1.5, 2.5, 3.5]
        array2 = [2.0, 1.5, 3.0]
        result = described_class.mult(array1, array2)
        expect(result).to eq([3.0, 3.75, 10.5])
      end

      it "handles negative numbers" do
        array1 = [-1.0, 2.0, -3.0]
        array2 = [2.0, -2.0, 3.0]
        result = described_class.mult(array1, array2)
        expect(result).to eq([-2.0, -4.0, -9.0])
      end

      it "handles arrays with zeros" do
        array1 = [1.0, 0.0, 3.0]
        array2 = [2.0, 5.0, 0.0]
        result = described_class.mult(array1, array2)
        expect(result).to eq([2.0, 0.0, 0.0])
      end

      it "handles very large numbers" do
        array1 = [1e10, 2e10, 3e10]
        array2 = [2.0, 3.0, 4.0]
        result = described_class.mult(array1, array2)
        expect(result).to eq([2e10, 6e10, 1.2e11])
      end

      it "handles very small numbers" do
        array1 = [1e-10, 2e-10, 3e-10]
        array2 = [2.0, 3.0, 4.0]
        result = described_class.mult(array1, array2)
        expect(result).to eq([2e-10, 6e-10, 1.2e-9])
      end

      it "returns array of same length as inputs" do
        array1 = [1.0, 2.0, 3.0, 4.0, 5.0]
        array2 = [2.0, 3.0, 4.0, 5.0, 6.0]
        result = described_class.mult(array1, array2)
        expect(result.length).to eq(array1.length)
      end
    end

    describe "#sub" do
      it_behaves_like "ta_lib_input_validation", :sub

      it "subtracts two arrays element by element" do
        result = described_class.sub(first_price_set, second_price_set)
        expect(result).to eq([-1.0, 0.0, 0.0, -1.0, 0.0])
      end

      it "handles floating point subtraction" do
        array1 = [1.5, 2.5, 3.5]
        array2 = [0.5, 1.5, 2.0]
        result = described_class.sub(array1, array2)
        expect(result).to eq([1.0, 1.0, 1.5])
      end

      it "handles negative numbers" do
        array1 = [-1.0, 2.0, -3.0]
        array2 = [2.0, -2.0, 3.0]
        result = described_class.sub(array1, array2)
        expect(result).to eq([-3.0, 4.0, -6.0])
      end

      it "handles arrays with zeros" do
        array1 = [1.0, 0.0, 3.0]
        array2 = [0.0, 5.0, 0.0]
        result = described_class.sub(array1, array2)
        expect(result).to eq([1.0, -5.0, 3.0])
      end

      it "handles very large numbers" do
        array1 = [1e10, 2e10, 3e10]
        array2 = [2.0, 3.0, 4.0]
        result = described_class.sub(array1, array2)
        expect(result).to eq([1e10 - 2.0, 2e10 - 3.0, 3e10 - 4.0])
      end

      it "handles very small numbers" do
        array1 = [1e-10, 2e-10, 3e-10]
        array2 = [1e-11, 2e-11, 3e-11]
        result = described_class.sub(array1, array2)
        expect(result).to eq([9e-11, 1.8e-10, 2.7e-10])
      end

      it "returns array of same length as inputs" do
        array1 = [1.0, 2.0, 3.0, 4.0, 5.0]
        array2 = [2.0, 3.0, 4.0, 5.0, 6.0]
        result = described_class.sub(array1, array2)
        expect(result.length).to eq(array1.length)
      end
    end

    describe "#sum" do
      it_behaves_like "ta_lib_input_validation", :sum

      it "calculates running sum over period" do
        result = described_class.sum(first_price_set, time_period: 2)
        expect(result).to eq([3.0, 5.0, 7.0, 9.0])
      end

      it "uses default time period (30) when not specified" do
        result = described_class.sum(Array.new(50, 1.0))
        expect(result.length).to eq(21)
        expect(result.first).to eq(30.0)
      end

      it "handles floating point numbers" do
        data = [1.5, 2.5, 3.5, 4.5, 5.5]
        result = described_class.sum(data, time_period: 3)
        expect(result).to eq([7.5, 10.5, 13.5])
      end

      it "handles negative numbers" do
        data = [-1.0, -2.0, -3.0, -4.0, -5.0]
        result = described_class.sum(data, time_period: 3)
        expect(result).to eq([-6.0, -9.0, -12.0])
      end

      it "handles mixed positive and negative numbers" do
        data = [-1.0, 2.0, -3.0, 4.0, -5.0]
        result = described_class.sum(data, time_period: 3)
        expect(result).to eq([-2.0, 3.0, -4.0])
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.sum(first_price_set, time_period: first_price_set.length + 1)
        expect(result).to be_empty
      end

      it "handles very large numbers" do
        data = [1e10, 2e10, 3e10, 4e10, 5e10]
        result = described_class.sum(data, time_period: 3)
        expect(result).to eq([6e10, 9e10, 1.2e11])
      end

      it "handles very small numbers" do
        data = [1e-10, 2e-10, 3e-10, 4e-10, 5e-10]
        result = described_class.sum(data, time_period: 3)
        expect(result).to eq([6e-10, 9e-10, 1.2e-9])
      end

      it "raises error when time period is less than 1" do
        expect { described_class.sum(first_price_set, time_period: 0) }
          .to raise_error(described_class::TALibError)
      end

      it "handles arrays with zeros" do
        data = [1.0, 0.0, 2.0, 0.0, 3.0]
        result = described_class.sum(data, time_period: 3)
        expect(result).to eq([3.0, 2.0, 5.0])
      end
    end
  end

  describe "Math Transform" do
    describe "#acos" do
      it_behaves_like "ta_lib_input_validation", :acos

      it "calculates arc cosine for valid input range" do
        data = [1.0, 0.5, 0.0, -0.5, -1.0]
        result = described_class.acos(data)
        expect(result.map { |x| x.round(6) }).to eq([0.0, 1.047198, 1.570796, 2.094395, 3.141593])
      end

      it "handles array of zeros" do
        result = described_class.acos([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(Math::PI / 2))
      end

      it "handles array of ones" do
        result = described_class.acos([1.0, 1.0, 1.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "handles array of negative ones" do
        result = described_class.acos([-1.0, -1.0, -1.0])
        expect(result).to all(be_within(0.000001).of(Math::PI))
      end

      it "returns NaN for values outside [-1, 1]" do
        result = described_class.acos([2.0, -2.0])
        expect(result).to all(be_nan)
      end
    end

    describe "#asin" do
      it_behaves_like "ta_lib_input_validation", :asin

      it "calculates arc sine for valid input range" do
        data = [1.0, 0.5, 0.0, -0.5, -1.0]
        result = described_class.asin(data)
        expect(result.map { |x| x.round(6) }).to eq([1.570796, 0.523599, 0.0, -0.523599, -1.570796])
      end

      it "handles array of zeros" do
        result = described_class.asin([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "handles array of ones" do
        result = described_class.asin([1.0, 1.0, 1.0])
        expect(result).to all(be_within(0.000001).of(Math::PI / 2))
      end

      it "handles array of negative ones" do
        result = described_class.asin([-1.0, -1.0, -1.0])
        expect(result).to all(be_within(0.000001).of(-Math::PI / 2))
      end

      it "returns NaN for values outside [-1, 1]" do
        result = described_class.asin([2.0, -2.0])
        expect(result).to all(be_nan)
      end
    end

    describe "#atan" do
      it_behaves_like "ta_lib_input_validation", :atan

      it "calculates arc tangent" do
        data = [1.0, 0.0, -1.0, 2.0, -2.0]
        result = described_class.atan(data)
        expect(result.map { |x| x.round(6) }).to eq([0.785398, 0.0, -0.785398, 1.107149, -1.107149])
      end

      it "handles array of zeros" do
        result = described_class.atan([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "handles very large positive numbers" do
        result = described_class.atan([1e10])
        expect(result.first).to be_within(0.000001).of(Math::PI / 2)
      end

      it "handles very large negative numbers" do
        result = described_class.atan([-1e10])
        expect(result.first).to be_within(0.000001).of(-Math::PI / 2)
      end
    end

    describe "#ceil" do
      it_behaves_like "ta_lib_input_validation", :ceil

      it "calculates ceiling values" do
        data = [1.1, 2.9, -1.1, -2.9, 3.0]
        result = described_class.ceil(data)
        expect(result).to eq([2.0, 3.0, -1.0, -2.0, 3.0])
      end

      it "handles integers" do
        data = [1.0, 2.0, 3.0]
        result = described_class.ceil(data)
        expect(result).to eq(data)
      end

      it "handles zeros" do
        result = described_class.ceil([0.0, -0.0, 0.1, -0.1])
        expect(result).to eq([0.0, 0.0, 1.0, 0.0])
      end
    end

    describe "#cos" do
      it_behaves_like "ta_lib_input_validation", :cos

      it "calculates cosine" do
        data = [0.0, Math::PI / 2, Math::PI, -Math::PI / 2, -Math::PI]
        result = described_class.cos(data)
        expect(result.map { |x| x.round(6) }).to eq([1.0, 0.0, -1.0, 0.0, -1.0])
      end

      it "handles array of zeros" do
        result = described_class.cos([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(1.0))
      end

      it "handles periodic nature" do
        result = described_class.cos([2 * Math::PI])
        expect(result.first).to be_within(0.000001).of(1.0)
      end
    end

    describe "#cosh" do
      it_behaves_like "ta_lib_input_validation", :cosh

      it "calculates hyperbolic cosine" do
        data = [0.0, 1.0, -1.0, 2.0, -2.0]
        result = described_class.cosh(data)
        expect(result.map { |x| x.round(6) }).to eq([1.0, 1.543081, 1.543081, 3.762196, 3.762196])
      end

      it "handles array of zeros" do
        result = described_class.cosh([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(1.0))
      end

      it "is symmetric around zero" do
        result = described_class.cosh([1.0, -1.0])
        expect(result[0]).to be_within(0.000001).of(result[1])
      end
    end

    describe "#exp" do
      it_behaves_like "ta_lib_input_validation", :exp

      it "calculates exponential" do
        data = [0.0, 1.0, -1.0, 2.0, -2.0]
        result = described_class.exp(data)
        expect(result.map { |x| x.round(6) }).to eq([1.0, 2.718282, 0.367879, 7.389056, 0.135335])
      end

      it "handles array of zeros" do
        result = described_class.exp([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(1.0))
      end

      it "handles large negative numbers" do
        result = described_class.exp([-100.0])
        expect(result.first).to be_within(0.000001).of(0.0)
      end
    end

    describe "#floor" do
      it_behaves_like "ta_lib_input_validation", :floor

      it "calculates floor values" do
        data = [1.1, 2.9, -1.1, -2.9, 3.0]
        result = described_class.floor(data)
        expect(result).to eq([1.0, 2.0, -2.0, -3.0, 3.0])
      end

      it "handles integers" do
        data = [1.0, 2.0, 3.0]
        result = described_class.floor(data)
        expect(result).to eq(data)
      end

      it "handles zeros" do
        result = described_class.floor([0.0, -0.0, 0.1, -0.1])
        expect(result).to eq([0.0, 0.0, 0.0, -1.0])
      end
    end

    describe "#ln" do
      it_behaves_like "ta_lib_input_validation", :ln

      it "calculates natural logarithm" do
        data = [1.0, Math::E, Math::E**2, 10.0]
        result = described_class.ln(data)
        expect(result.map { |x| x.round(6) }).to eq([0.0, 1.0, 2.0, 2.302585])
      end

      it "handles array of ones" do
        result = described_class.ln([1.0, 1.0, 1.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "returns negative infinity for zero" do
        result = described_class.ln([0.0])
        expect(result).to eq([-Float::INFINITY])
      end

      it "returns NaN for negative numbers" do
        result = described_class.ln([-1.0])
        expect(result).to all(be_nan)
      end
    end

    describe "#log10" do
      it_behaves_like "ta_lib_input_validation", :log10

      it "calculates base-10 logarithm" do
        data = [1.0, 10.0, 100.0, 1000.0]
        result = described_class.log10(data)
        expect(result.map { |x| x.round(6) }).to eq([0.0, 1.0, 2.0, 3.0])
      end

      it "returns negative infinity for zero" do
        result = described_class.log10([0.0])
        expect(result).to eq([-Float::INFINITY])
      end

      it "returns NaN for negative numbers" do
        result = described_class.log10([-1.0])
        expect(result).to all(be_nan)
      end
    end

    describe "#sin" do
      it_behaves_like "ta_lib_input_validation", :sin

      it "calculates sine" do
        data = [0.0, Math::PI / 2, Math::PI, -Math::PI / 2, -Math::PI]
        result = described_class.sin(data)
        expect(result.map { |x| x.round(6) }).to eq([0.0, 1.0, 0.0, -1.0, 0.0])
      end

      it "handles array of zeros" do
        result = described_class.sin([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "handles periodic nature" do
        result = described_class.sin([2 * Math::PI])
        expect(result.first).to be_within(0.000001).of(0.0)
      end
    end

    describe "#sinh" do
      it_behaves_like "ta_lib_input_validation", :sinh

      it "calculates hyperbolic sine" do
        data = [0.0, 1.0, -1.0, 2.0, -2.0]
        result = described_class.sinh(data)
        expect(result.map { |x| x.round(6) }).to eq([0.0, 1.175201, -1.175201, 3.626860, -3.626860])
      end

      it "handles array of zeros" do
        result = described_class.sinh([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "is antisymmetric around zero" do
        result = described_class.sinh([1.0, -1.0])
        expect(result[0]).to be_within(0.000001).of(-result[1])
      end
    end

    describe "#sqrt" do
      it_behaves_like "ta_lib_input_validation", :sqrt

      it "calculates square root" do
        data = [0.0, 1.0, 4.0, 9.0, 16.0]
        result = described_class.sqrt(data)
        expect(result.map { |x| x.round(6) }).to eq([0.0, 1.0, 2.0, 3.0, 4.0])
      end

      it "handles array of zeros" do
        result = described_class.sqrt([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "returns NaN for negative numbers" do
        result = described_class.sqrt([-1.0, -4.0])
        expect(result).to all(be_nan)
      end
    end

    describe "#tan" do
      it_behaves_like "ta_lib_input_validation", :tan

      it "calculates tangent" do
        data = [0.0, Math::PI / 4, -Math::PI / 4]
        result = described_class.tan(data)
        expect(result.map { |x| x.round(6) }).to eq([0.0, 1.0, -1.0])
      end

      it "handles array of zeros" do
        result = described_class.tan([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "handles periodic nature" do
        result = described_class.tan([Math::PI])
        expect(result.first).to be_within(0.000001).of(0.0)
      end
    end

    describe "#tanh" do
      it_behaves_like "ta_lib_input_validation", :tanh

      it "calculates hyperbolic tangent" do
        data = [0.0, 1.0, -1.0, 2.0, -2.0]
        result = described_class.tanh(data)
        expect(result.map { |x| x.round(6) }).to eq([0.0, 0.761594, -0.761594, 0.964028, -0.964028])
      end

      it "handles array of zeros" do
        result = described_class.tanh([0.0, 0.0, 0.0])
        expect(result).to all(be_within(0.000001).of(0.0))
      end

      it "is antisymmetric around zero" do
        result = described_class.tanh([1.0, -1.0])
        expect(result[0]).to be_within(0.000001).of(-result[1])
      end

      it "approaches ±1 for large values" do
        result = described_class.tanh([10.0, -10.0])
        expect(result[0]).to be_within(0.000001).of(1.0)
        expect(result[1]).to be_within(0.000001).of(-1.0)
      end
    end
  end

  describe "Overlap Studies" do
    let(:high_prices) { [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 10.0] }
    let(:close_prices) { [9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 9.0] }
    let(:low_prices) { [8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 8.0] }

    describe "#accbands" do
      it_behaves_like "ta_lib_input_validation", :accbands

      it "calculates Acceleration Bands" do
        result = described_class.accbands([high_prices, low_prices, close_prices], time_period: 2)
        expect(result).to match(upper_band: an_instance_of(Array), middle_band: an_instance_of(Array), lower_band: an_instance_of(Array))
      end

      it "uses default time period (20) when not specified" do
        result = described_class.accbands([high_prices, low_prices, close_prices])
        expect(result[:upper_band].length).to eq([high_prices.length - 19, 0].max)
      end

      it "respects specified time period" do
        result = described_class.accbands([high_prices, low_prices, close_prices], time_period: 7)
        expect(result[:upper_band].length).to eq(high_prices.length - 6)
      end

      it "returns empty arrays when period exceeds data length" do
        result = described_class.accbands([high_prices, low_prices, close_prices], time_period: high_prices.length + 1)
        expect(result[:upper_band]).to be_empty
        expect(result[:middle_band]).to be_empty
        expect(result[:lower_band]).to be_empty
      end
    end

    describe "#bbands" do
      it_behaves_like "ta_lib_input_validation", :bbands

      it "calculates Bollinger Bands" do
        result = described_class.bbands(close_prices, time_period: 5)
        expect(result).to be_a(Hash)
        expect(result.keys).to contain_exactly(:upper_band, :middle_band, :lower_band)
        expect(result).to match(upper_band: an_instance_of(Array), middle_band: an_instance_of(Array), lower_band: an_instance_of(Array))
      end

      it "uses default parameters when not specified" do
        result1 = described_class.bbands(close_prices)
        result2 = described_class.bbands(close_prices, time_period: 5, nb_dev_up: 2.0, nb_dev_dn: 2.0, ma_type: 0)
        expect(result1).to eq(result2)
      end

      it "handles custom deviation multiplier" do
        result1 = described_class.bbands(close_prices, time_period: 5, nb_dev_up: 1.0, nb_dev_dn: 1.0)
        result2 = described_class.bbands(close_prices, time_period: 5, nb_dev_up: 2.0, nb_dev_dn: 2.0)
        expect(result2[:upper_band].first).to be > result1[:upper_band].first
        expect(result2[:lower_band].first).to be < result1[:lower_band].first
      end

      it "returns empty arrays when period exceeds data length" do
        result = described_class.bbands(close_prices, time_period: close_prices.length + 1)
        expect(result.values).to all(be_empty)
      end
    end

    describe "#dema" do
      it_behaves_like "ta_lib_input_validation", :dema

      it "calculates Double Exponential Moving Average" do
        result = described_class.dema(close_prices, time_period: 3)
        expect(result).to be_an(Array)
        expect(result.length).to eq(close_prices.length - 2 * 3 + 2)
      end

      it "uses default time period (30) when not specified" do
        result = described_class.dema(close_prices)
        expect(result.length).to eq([close_prices.length - 29, 0].max)
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.dema(close_prices, time_period: close_prices.length + 1)
        expect(result).to be_empty
      end

      it "handles constant price series" do
        constant_prices = Array.new(10, 10.0)
        result = described_class.dema(constant_prices, time_period: 3)
        expect(result).to all(be_within(0.000001).of(10.0))
      end

      it "calculates exact results for close_prices" do
        result = described_class.dema(close_prices, time_period: 3)
        expect(result).to eq([13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 11.5])
      end
    end

    describe "#ema" do
      it_behaves_like "ta_lib_input_validation", :ema

      it "calculates Exponential Moving Average" do
        result = described_class.ema(close_prices, time_period: 5)
        expect(result).to be_an(Array)
        expect(result.length).to eq(close_prices.length - 5 + 1)
      end

      it "uses default time period (30) when not specified" do
        result = described_class.ema(close_prices)
        expect(result.length).to eq([close_prices.length - 29, 0].max)
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.ema(close_prices, time_period: close_prices.length + 1)
        expect(result).to be_empty
      end

      it "handles constant price series" do
        constant_prices = Array.new(10, 10.0)
        result = described_class.ema(constant_prices, time_period: 3)
        expect(result).to all(be_within(0.000001).of(10.0))
      end

      it "calculates exact results for close_prices" do
        result = described_class.ema(close_prices, time_period: 3)
        expect(result).to eq([10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 13.0])
      end
    end

    describe "#ht_trendline" do
      it_behaves_like "ta_lib_input_validation", :ht_trendline

      it "calculates Hilbert Transform - Instantaneous Trendline" do
        result = described_class.ht_trendline(close_prices)
        expect(result).to be_an(Array)
        expect(result.length).to be <= close_prices.length
      end

      it "handles constant price series" do
        constant_prices = Array.new(200, 10.0)
        result = described_class.ht_trendline(constant_prices)
        expect(result).not_to be_empty
        expect(result).to all(be_within(0.000001).of(10.0))
      end
    end

    describe "#kama" do
      it_behaves_like "ta_lib_input_validation", :kama

      it "calculates Kaufman Adaptive Moving Average" do
        result = described_class.kama(close_prices, time_period: 5)
        expect(result).to be_an(Array)
        expect(result.length).to eq(6)
      end

      it "uses default time period (30) when not specified" do
        result = described_class.kama(close_prices)
        expect(result.length).to eq([close_prices.length - 29, 0].max)
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.kama(close_prices, time_period: close_prices.length + 1)
        expect(result).to be_empty
      end

      it "handles constant price series" do
        constant_prices = Array.new(10, 10.0)
        result = described_class.kama(constant_prices, time_period: 3)
        expect(result).to all(be_within(0.000001).of(10.0))
      end
    end

    describe "#ma" do
      it_behaves_like "ta_lib_input_validation", :ma

      it "calculates Moving Average with different types" do
        result_sma = described_class.ma(close_prices, time_period: 5, ma_type: 0)
        result_ema = described_class.ma(close_prices, time_period: 5, ma_type: 1)
        expect(result_sma).to be_an(Array)
        expect(result_ema).to be_an(Array)
        expect(result_sma).not_to eq(result_ema)
      end

      it "uses default parameters when not specified" do
        result = described_class.ma(close_prices)
        expect(result.length).to eq([close_prices.length - 29, 0].max)
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.ma(close_prices, time_period: close_prices.length + 1)
        expect(result).to be_empty
      end

      it "handles constant price series" do
        constant_prices = Array.new(10, 10.0)
        result = described_class.ma(constant_prices, time_period: 3)
        expect(result).to all(be_within(0.000001).of(10.0))
      end

      it "calculates Moving Average with specific results" do
        result = described_class.ma([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], time_period: 3, ma_type: 0)
        expect(result).to eq([2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0])
      end

      it "calculates Exponential Moving Average with specific results" do
        result = described_class.ma([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], time_period: 3, ma_type: 1)
        expect(result).to eq([2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0])
      end
    end

    describe "#mama" do
      it_behaves_like "ta_lib_input_validation", :mama

      it "calculates MESA Adaptive Moving Average" do
        result = described_class.mama(close_prices)
        expect(result).to be_a(Hash)
        expect(result.keys).to contain_exactly(:mama, :fama)
        expect(result[:mama]).to be_an(Array)
        expect(result[:fama]).to be_an(Array)
      end

      it "handles custom fast and slow limits" do
        result = described_class.mama(close_prices, fast_limit: 0.5, slow_limit: 0.05)
        expect(result[:mama]).to be_an(Array)
        expect(result[:fama]).to be_an(Array)
      end

      it "uses default fast and slow limits (0.5, 0.05) when not specified" do
        result = described_class.mama(close_prices)
        result2 = described_class.mama(close_prices, fast_limit: 0.5, slow_limit: 0.05)
        expect(result).to eq(result2)
      end
    end

    describe "#mavp" do
      let(:periods) { [2.0, 3.0, 4.0, 5.0, 4.0, 3.0, 2.0, 3.0, 4.0, 5.0, 4.0] }

      it_behaves_like "ta_lib_input_validation", :mavp

      it "calculates Moving Average with Variable Period" do
        result = described_class.mavp(close_prices, periods, min_period: 2, max_period: 5)
        expect(result).to be_an(Array)
      end

      it "respects minimum and maximum periods" do
        result = described_class.mavp(close_prices, periods, min_period: 2, max_period: 3)
        expect(result).to be_an(Array)
      end

      it "returns empty array when data length is insufficient" do
        result = described_class.mavp(close_prices[0..2], periods[0..2], min_period: 5, max_period: 10)
        expect(result).to be_empty
      end
    end

    describe "#midpoint" do
      it_behaves_like "ta_lib_input_validation", :midpoint

      it "calculates MidPoint over period" do
        result = described_class.midpoint(close_prices, time_period: 5)
        expect(result).to be_an(Array)
        expect(result.length).to eq(7)
      end

      it "uses default time period (14) when not specified" do
        result = described_class.midpoint(close_prices)
        expect(result.length).to eq([close_prices.length - 13, 0].max)
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.midpoint(close_prices, time_period: close_prices.length + 1)
        expect(result).to be_empty
      end

      it "handles constant price series" do
        constant_prices = Array.new(10, 10.0)
        result = described_class.midpoint(constant_prices, time_period: 3)
        expect(result).to all(be_within(0.000001).of(10.0))
      end
    end

    describe "#midprice" do
      it_behaves_like "ta_lib_input_validation", :midprice

      it "calculates MidPrice over period" do
        result = described_class.midprice([high_prices, low_prices], time_period: 2)
        expect(result).to be_an(Array)
        expect(result.length).to eq(high_prices.length - 1)
      end

      it "uses default time period (14) when not specified" do
        result = described_class.midprice([high_prices, low_prices])
        expect(result.length).to eq([high_prices.length - 13, 0].max)
      end

      it "returns empty array when period exceeds data length" do
        result = described_class.midprice([high_prices, low_prices], time_period: high_prices.length + 1)
        expect(result).to be_empty
      end

      it "handles constant price series" do
        constant_high = Array.new(10, 11.0)
        constant_low = Array.new(10, 9.0)
        result = described_class.midprice([constant_high, constant_low], time_period: 2)
        expect(result).to all(be_within(0.000001).of(10.0))
      end
    end

    describe "#sar" do
      it_behaves_like "ta_lib_input_validation", :sar

      it "calculates Parabolic SAR with default parameters" do
        result = described_class.sar([high_prices, low_prices])
        expect(result).to be_an(Array)
        expect(result.length).to eq(high_prices.length - 1)
      end

      it "calculates Parabolic SAR with custom acceleration and maximum parameters" do
        result = described_class.sar([high_prices, low_prices], acceleration: 0.02, maximum: 0.2)
        expect(result).to be_an(Array)
        expect(result.length).to eq(high_prices.length - 1)
      end

      it "uses default parameters when not specified" do
        result1 = described_class.sar([high_prices, low_prices])
        result2 = described_class.sar([high_prices, low_prices], acceleration: 0.02, maximum: 0.2)
        expect(result1).to eq(result2)
      end

      it "raises error when acceleration is negative" do
        expect { described_class.sar([high_prices, low_prices], acceleration: -0.02) }.to raise_error(described_class::TALibError)
      end

      it "raises error when maximum is negative" do
        expect { described_class.sar([high_prices, low_prices], maximum: -0.2) }.to raise_error(described_class::TALibError)
      end
    end
  end

  describe "Function Information" do
    it "exposes the native indicator descriptions" do
      expect(described_class.function_description_xml).to include("<Abbreviation>SMA</Abbreviation>")
    end

    it "can get function groups" do
      groups = described_class.group_table
      expect(groups).to be_an(Array)
      expect(groups).not_to be_empty
    end

    it "can get functions for specific group" do
      funcs = described_class.function_table("Math Operators")
      expect(funcs).to be_an(Array)
      expect(funcs).not_to be_empty
    end

    it "can get function information" do
      info = described_class.function_info("SMA")
      expect(info).not_to be_nil
      expect(info["name"].to_s).to eq("SMA")
    end
  end
end
