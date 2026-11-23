# frozen_string_literal: true

require "fiddle"
require "rexml/document"

# Build direct TA_<indicator> calls from the native library's published signatures.
# Only the loaded library handle is shared with the Ruby binding under test.
class CReference
  INT = Fiddle::TYPE_INT
  PTR = Fiddle::TYPE_VOIDP
  OPTION_TYPES = { "Integer" => INT, "MA Type" => INT, "Double" => Fiddle::TYPE_DOUBLE }.freeze
  OUTPUT_FORMATS = { "Double Array" => "d", "Integer Array" => "i!" }.freeze
  PRICE_INPUTS = %w[Open High Low Close Volume].freeze

  attr_reader :name, :defaults

  def self.bind(symbol, arguments, return_type)
    address = TALibFFI.handler.sym(symbol) || raise("Missing TA-Lib export #{symbol}")
    Fiddle::Function.new(address, arguments, return_type)
  end

  def self.functions
    xml = bind("TA_FunctionDescriptionXML", [], PTR).call.to_s
    REXML::Document.new(xml).root.get_elements("FinancialFunction").to_h do |definition|
      reference = new(definition)
      [reference.name, reference]
    end
  end

  def initialize(definition)
    @name = definition.elements["Abbreviation"].text
    @inputs = argument_fields(definition, "RequiredInput", "Name")
    @formats = OUTPUT_FORMATS.fetch_values(*argument_fields(definition, "Output", "Type"))
    option_types = OPTION_TYPES.fetch_values(*argument_fields(definition, "OptionalInput", "Type"))
    @defaults = option_defaults(definition, option_types)
    @function = CReference.bind("TA_#{name}", signature(option_types), INT)
  end

  # Ruby groups adjacent OHLCV fields into one argument. The direct C API
  # receives a separate pointer for each field, in declaration order.
  def ruby_inputs(series)
    @inputs.chunk { |name| PRICE_INPUTS.include?(name) }.flat_map do |prices, names|
      arrays = series.fetch_values(*names)
      prices ? [arrays] : arrays
    end
  end

  def call(series, options = defaults)
    inputs = series.fetch_values(*@inputs)
    length = input_length(inputs)
    buffers = @formats.map { |format| Array.new(length, 0).pack("#{format}*") }
    size = run(length, inputs, options, buffers)
    buffers.zip(@formats).map { |buffer, format| buffer.unpack("#{format}#{size}") }
  end

  private

  def argument_fields(definition, kind, field)
    definition.get_elements("#{kind}Arguments/#{kind}Argument/#{field}").map(&:text)
  end

  def option_defaults(definition, types)
    values = argument_fields(definition, "OptionalInput", "DefaultValue")
    types.zip(values).map { |type, value| type == INT ? Integer(value, 10) : Float(value) }
  end

  def signature(option_types)
    [INT, INT, *Array.new(@inputs.size, PTR), *option_types, PTR, PTR, *Array.new(@formats.size, PTR)]
  end

  def input_length(inputs)
    length = inputs.first.length
    return length if length.positive? && inputs.all? { |input| input.size == length }

    raise ArgumentError, "TA_#{name} needs equally sized, nonempty inputs"
  end

  def run(length, inputs, options, buffers)
    first = [0].pack("i!")
    count = [0].pack("i!")
    status = @function.call(0, length - 1, *inputs.map { |input| input.pack("d*") }, *options, first, count, *buffers)
    raise "TA_#{@name} returned code #{status}" unless status.zero?

    size = count.unpack1("i!")
    return size if size.between?(0, length) && (size.zero? || first.unpack1("i!") + size == length)

    raise "TA_#{@name} returned an invalid output range"
  end
end
