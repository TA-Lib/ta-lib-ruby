# frozen_string_literal: true

require "fiddle"
require "fiddle/import"
require "rubygems/version"
require_relative "ta_lib_ffi/version"

# Ruby FFI wrapper for TA-Lib (Technical Analysis Library)
#
# This module provides a Ruby interface to the TA-Lib technical analysis library
# using FFI (Foreign Function Interface). It allows you to perform various
# technical analysis calculations on financial market data.
#
# @example Basic usage
#   require 'ta_lib_ffi'
#
#   # Calculate Simple Moving Average
#   prices = [10.0, 11.0, 12.0, 11.0, 10.0]
#   result = TALibFFI.sma(prices, time_period: 3)
#
# @see https://ta-lib.org/ TA-Lib Official Website
module TALibFFI
  if defined?(Zeitwerk)
    # https://github.com/fxn/zeitwerk?tab=readme-ov-file#custom-inflector
    # @!visibility private
    class Inflector < Zeitwerk::GemInflector
      def camelize(basename, _abspath)
        case basename
        when "ta_lib_ffi"
          "TALibFFI"
        else
          super
        end
      end
    end
  end

  extend Fiddle::Importer

  lib_path = ENV.fetch("TA_LIB_PATH") do
    case RUBY_PLATFORM
    when /darwin/ then "#{`brew --prefix`.chomp}/lib/libta-lib.dylib"
    when /linux/ then "libta-lib.so"
    when /cygwin|mswin|mingw|bccwin|wince|emx/ then "C:/Program Files/TA-Lib/bin/ta-lib.dll"
    else raise "Unsupported platform: #{RUBY_PLATFORM}"
    end
  end

  dlload lib_path

  class TALibError < StandardError; end

  TA_SUCCESS                    = 0
  TA_LIB_NOT_INITIALIZE         = 1
  TA_BAD_PARAM                  = 2
  TA_ALLOC_ERR                  = 3
  TA_GROUP_NOT_FOUND            = 4
  TA_FUNC_NOT_FOUND             = 5
  TA_INVALID_HANDLE             = 6
  TA_INVALID_PARAM_HOLDER       = 7
  TA_INVALID_PARAM_HOLDER_TYPE  = 8
  TA_INVALID_PARAM_FUNCTION     = 9
  TA_INPUT_NOT_ALL_INITIALIZE   = 10
  TA_OUTPUT_NOT_ALL_INITIALIZE  = 11
  TA_OUT_OF_RANGE_START_INDEX   = 12
  TA_OUT_OF_RANGE_END_INDEX     = 13
  TA_INVALID_LIST_TYPE          = 14
  TA_BAD_OBJECT                 = 15
  TA_NOT_SUPPORTED              = 16
  TA_INTERNAL_ERROR             = 5000
  TA_UNKNOWN_ERR                = 0xFFFF

  typealias "TA_Real", "double"
  typealias "TA_Integer", "int"
  typealias "TA_RetCode", "int"
  typealias "TA_FuncHandle", "unsigned int"
  typealias "TA_FuncFlags", "int"
  typealias "TA_CallForEachFunc", "void *"
  typealias "TA_InputParameterType", "int"
  typealias "TA_InputFlags", "int"
  typealias "TA_OptInputParameterType", "int"
  typealias "TA_OptInputFlags", "int"
  typealias "TA_OutputParameterType", "int"
  typealias "TA_OutputFlags", "int"

  TA_StringTable = struct [
    "unsigned int size",
    "const char **string",
    "void *hiddenData"
  ]

  # TA-Lib 0.8.1 removed camelCaseName. Older Windows DLLs can omit
  # TA_GetVersionString entirely and use the original struct layout.
  version_export = handler.sym("TA_GetVersionString")
  if version_export
    version_string = Fiddle::Function.new(version_export, [], Fiddle::TYPE_VOIDP).call.to_s
    native_version = Gem::Version.new(version_string.split.first)
  end
  legacy_func_info = !native_version || native_version < Gem::Version.new("0.8.1")
  TA_FuncInfo = struct [
    "const char *name",
    "const char *group",
    "const char *hint",
    *(["const char *camelCaseName"] if legacy_func_info),
    "TA_FuncFlags flags",
    "unsigned int nbInput",
    "unsigned int nbOptInput",
    "unsigned int nbOutput",
    "const TA_FuncHandle *handle"
  ]

  TA_ParamHolder = struct [
    "void *hiddenData"
  ]

  TA_InputParameterInfo = struct [
    "TA_InputParameterType type",
    "const char *paramName",
    "TA_InputFlags flags"
  ]

  TA_OptInputParameterInfo = struct [
    "TA_OptInputParameterType type",
    "const char *paramName",
    "TA_OptInputFlags flags",
    "const char *displayName",
    "const void *dataSet",
    "TA_Real defaultValue",
    "const char *hint",
    "const char *helpFile"
  ]

  TA_OutputParameterInfo = struct [
    "TA_OutputParameterType type",
    "const char *paramName",
    "TA_OutputFlags flags"
  ]

  TA_PARAM_TYPE = {
    TA_Input_Price: 0,
    TA_Input_Real: 1,
    TA_Input_Integer: 2,
    TA_OptInput_RealRange: 0,
    TA_OptInput_RealList: 1,
    TA_OptInput_IntegerRange: 2,
    TA_OptInput_IntegerList: 3,
    TA_Output_Real: 0,
    TA_Output_Integer: 1
  }.freeze

  PRICE_FIELDS = %w[open high low close volume open_interest].freeze
  OUTPUT_LAYOUTS = {
    TA_PARAM_TYPE[:TA_Output_Real] => ["d", Fiddle::SIZEOF_DOUBLE, :TA_SetOutputParamRealPtr].freeze,
    TA_PARAM_TYPE[:TA_Output_Integer] => ["i!", Fiddle::SIZEOF_INT, :TA_SetOutputParamIntegerPtr].freeze
  }.freeze
  private_constant :PRICE_FIELDS, :OUTPUT_LAYOUTS

  TA_FLAGS = {
    TA_InputFlags: {
      TA_IN_PRICE_OPEN: 0x00000001,
      TA_IN_PRICE_HIGH: 0x00000002,
      TA_IN_PRICE_LOW: 0x00000004,
      TA_IN_PRICE_CLOSE: 0x00000008,
      TA_IN_PRICE_VOLUME: 0x00000010,
      TA_IN_PRICE_OPENINTEREST: 0x00000020,
      TA_IN_PRICE_TIMESTAMP: 0x00000040
    },
    TA_OptInputFlags: {
      TA_OPTIN_IS_PERCENT: 0x00100000,
      TA_OPTIN_IS_DEGREE: 0x00200000,
      TA_OPTIN_IS_CURRENCY: 0x00400000,
      TA_OPTIN_ADVANCED: 0x01000000
    },
    TA_OutputFlags: {
      TA_OUT_LINE: 0x00000001,
      TA_OUT_DOT_LINE: 0x00000002,
      TA_OUT_DASH_LINE: 0x00000004,
      TA_OUT_DOT: 0x00000008,
      TA_OUT_HISTO: 0x00000010,
      TA_OUT_PATTERN_BOOL: 0x00000020,
      TA_OUT_PATTERN_BULL_BEAR: 0x00000040,
      TA_OUT_PATTERN_STRENGTH: 0x00000080,
      TA_OUT_POSITIVE: 0x00000100,
      TA_OUT_NEGATIVE: 0x00000200,
      TA_OUT_ZERO: 0x00000400,
      TA_OUT_UPPER_LIMIT: 0x00000800,
      TA_OUT_LOWER_LIMIT: 0x00001000,
      TA_OUT_NULLABLE: 0x00002000,
      TA_OUT_DISPLAY_SHIFT: 0x00004000,
      TA_OUT_PATTERN_WEAK: 0x00008000
    }
  }.freeze

  extern "int TA_Initialize()"
  extern "int TA_Shutdown()"
  extern "int TA_GroupTableAlloc(TA_StringTable**)"
  extern "int TA_GroupTableFree(TA_StringTable*)"
  extern "TA_RetCode TA_FuncTableAlloc(const char *group, TA_StringTable **table)"
  extern "TA_RetCode TA_FuncTableFree(TA_StringTable *table)"
  extern "TA_RetCode TA_GetFuncHandle(const char *name, const TA_FuncHandle **handle)"
  extern "TA_RetCode TA_GetFuncInfo(const TA_FuncHandle *handle, const TA_FuncInfo **funcInfo)"
  extern "TA_RetCode TA_ForEachFunc(TA_CallForEachFunc functionToCall, void *opaqueData)"
  extern "TA_RetCode TA_GetInputParameterInfo(const TA_FuncHandle *handle, unsigned int paramIndex, const TA_InputParameterInfo **info)"
  extern "TA_RetCode TA_GetOptInputParameterInfo(const TA_FuncHandle *handle, unsigned int paramIndex, const TA_OptInputParameterInfo **info)"
  extern "TA_RetCode TA_GetOutputParameterInfo(const TA_FuncHandle *handle, unsigned int paramIndex, const TA_OutputParameterInfo **info)"
  extern "TA_RetCode TA_ParamHolderAlloc(const TA_FuncHandle *handle, TA_ParamHolder **allocatedParams)"
  extern "TA_RetCode TA_ParamHolderFree(TA_ParamHolder *params)"
  extern "TA_RetCode TA_SetInputParamIntegerPtr(TA_ParamHolder *params, unsigned int paramIndex, const TA_Integer *value)"
  extern "TA_RetCode TA_SetInputParamRealPtr(TA_ParamHolder *params, unsigned int paramIndex, const TA_Real *value)"
  extern "TA_RetCode TA_SetInputParamPricePtr(TA_ParamHolder *params,
                                             unsigned int paramIndex,
                                             const TA_Real *open,
                                             const TA_Real *high,
                                             const TA_Real *low,
                                             const TA_Real *close,
                                             const TA_Real *volume,
                                             const TA_Real *openInterest)"
  extern "TA_RetCode TA_SetOptInputParamInteger(TA_ParamHolder *params, unsigned int paramIndex, TA_Integer optInValue)"
  extern "TA_RetCode TA_SetOptInputParamReal(TA_ParamHolder *params, unsigned int paramIndex, TA_Real optInValue)"
  extern "TA_RetCode TA_SetOutputParamIntegerPtr(TA_ParamHolder *params, unsigned int paramIndex, TA_Integer *out)"
  extern "TA_RetCode TA_SetOutputParamRealPtr(TA_ParamHolder *params, unsigned int paramIndex, TA_Real *out)"
  extern "TA_RetCode TA_GetLookback(const TA_ParamHolder *params, TA_Integer *lookback)"
  extern "TA_RetCode TA_CallFunc(const TA_ParamHolder *params,
                                TA_Integer startIdx,
                                TA_Integer endIdx,
                                TA_Integer *outBegIdx,
                                TA_Integer *outNbElement)"
  extern "const char *TA_FunctionDescriptionXML(void)"

  module_function

  # Extracts flags from a bitmask value based on the flag type
  #
  # @param value [Integer] The bitmask value to extract flags from
  # @param type [Symbol] The type of flags to extract (:TA_InputFlags, :TA_OptInputFlags, or :TA_OutputFlags)
  # @return [Array<Symbol>] Array of flag names that are set in the bitmask
  def extract_flags(value, type)
    TA_FLAGS.fetch(type).filter_map { |name, bit| name if (value & bit) != 0 }
  end

  # The caller owns only the pointer-sized output slot. TA-Lib determines the
  # lifetime of the address written into it (static metadata, a table or a holder).
  def native_pointer
    slot = [0].pack("J")
    check_ta_return_code(yield(slot))
    Fiddle::Pointer.new(slot.unpack1("J"))
  end
  private_class_method :native_pointer

  def string_table_names(pointer)
    table = TA_StringTable.new(pointer)
    return [] if table["size"].zero?

    table["string"].to_s(table["size"] * Fiddle::SIZEOF_VOIDP).unpack("J*").map { |address| Fiddle::Pointer.new(address).to_s }
  end
  private_class_method :string_table_names

  # Returns a list of all available function groups in TA-Lib
  #
  # @return [Array<String>] Array of group names
  def group_table
    table = native_pointer { |slot| TA_GroupTableAlloc(slot) }
    string_table_names(table)
  ensure
    TA_GroupTableFree(table) if table
  end

  # Returns a list of all functions in a specific group
  #
  # @param group [String] The name of the group to get functions for
  # @return [Array<String>] Array of function names in the group
  def function_table(group)
    table = native_pointer { |slot| TA_FuncTableAlloc(group, slot) }
    string_table_names(table)
  ensure
    TA_FuncTableFree(table) if table
  end

  # Gets detailed information about a specific TA-Lib function
  #
  # @param name [String] The name of the function to get information for
  # @return [Fiddle::CStructEntity] Struct containing function information
  def function_info(name)
    handle = get_function_handle(name)
    TA_FuncInfo.new(native_pointer { |slot| TA_GetFuncInfo(handle, slot) })
  end

  # Iterates over all available TA-Lib functions
  #
  # @yield [func_info] Yields function information for each function
  # @yieldparam func_info [Fiddle::CStructEntity] Function information struct
  def each_function(&block)
    callback = Fiddle::Closure::BlockCaller.new(
      Fiddle::TYPE_VOID,
      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
      Fiddle::Function::DEFAULT
    ) do |func_info_ptr, _|
      block.call TA_FuncInfo.new(func_info_ptr)
    end

    ret_code = TA_ForEachFunc(callback, nil)
    check_ta_return_code(ret_code)
  end

  # Prints detailed information about a TA-Lib function
  #
  # @param func_info [Fiddle::CStructEntity] Function information struct to print
  def print_function_info(func_info) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    puts "Function Name: #{func_info["name"]}"
    puts "Function Group: #{func_info["group"]}"
    puts "Function Hint: #{func_info["hint"]}"
    puts "Camel Case Name: #{func_info["camelCaseName"]}" if TA_FuncInfo.members.include?("camelCaseName")
    puts "Flags: #{func_info["flags"]}"
    puts "Number of Inputs: #{func_info["nbInput"]}"
    puts "Number of Optional Inputs: #{func_info["nbOptInput"]}"
    puts "Number of Outputs: #{func_info["nbOutput"]}"
    puts "Function Handle: #{func_info["handle"].to_i}"

    puts "\nInput Parameter Info:"
    collect_input_info(func_info).each_with_index do |param_info, i|
      puts "  Parameter #{i + 1}:"
      puts "    Name: #{param_info["paramName"]}"
      puts "    Type: #{param_info["type"]}"
      puts "    Flags: #{extract_flags(param_info["flags"], :TA_InputFlags)}"
    end

    puts "\nOptional Input Parameter Info:"
    collect_opt_input_info(func_info).each_with_index do |param_info, i|
      puts "  Parameter #{i + 1}:"
      puts "    Name: #{param_info["paramName"]}"
      puts "    Type: #{param_info["type"]}"
      puts "    Flags: #{extract_flags(param_info["flags"], :TA_OptInputFlags)}"
      puts "    Display Name: #{param_info["displayName"]}"
      puts "    Default Value: #{param_info["defaultValue"]}"
      puts "    Hint: #{param_info["hint"]}"
    end

    puts "\nOutput Parameter Info:"
    collect_output_info(func_info).each_with_index do |param_info, i|
      puts "  Parameter #{i + 1}:"
      puts "    Name: #{param_info["paramName"]}"
      puts "    Type: #{param_info["type"]}"
      puts "    Flags: #{extract_flags(param_info["flags"], :TA_OutputFlags)}"
    end
  end

  # Calls a TA-Lib function with the given arguments
  #
  # @param func_name [String] The name of the function to call
  # @param args [Array] Array of input arrays and optional parameters
  # @return [Array, Hash] Function results (single array or hash of named outputs)
  # @raise [TALibError] If there is an error in function execution
  def call_func(func_name, args)
    info = function_info_map.fetch(func_name) { raise TALibError, "Unknown TA-Lib function #{func_name.inspect}" }
    inputs, options = args.last.is_a?(Hash) ? [args[0...-1], args.last] : [args, {}]
    size = validate_inputs!(inputs, func_name)
    validate_options!(func_name, options, info[:keywords])
    run_indicator(info[:handle], func_name, inputs, options, size)
  end

  def run_indicator(handle, name, inputs, options, size)
    params = create_parameter_holder(handle)
    setup_input_parameters(params, inputs, name, size: size)
    setup_optional_parameters(params, options, name)
    calculate_results(params, inputs, name, input_size: size)
  rescue TALibError, TypeError, RangeError => e
    arguments = options.map { |key, value| "#{key}=#{value.inspect}" }.join(", ")
    raise TALibError, "#{name}(#{arguments}): #{e.message}"
  ensure
    TA_ParamHolderFree(params) if params
  end
  private_class_method :run_indicator

  # Calculates the lookback period for a function with given parameters
  #
  # @param params_ptr [Fiddle::Pointer] Pointer to parameter holder
  # @return [Integer] The lookback period
  def calculate_lookback(params_ptr)
    lookback = [0].pack("i!")
    check_ta_return_code(TA_GetLookback(params_ptr, lookback))
    lookback.unpack1("i!")
  end

  # Validates input arrays for TA-Lib functions
  #
  # @param arrays [Array<Array>] Arrays to validate
  # @raise [TALibError] If any array is invalid
  def validate_inputs!(arrays, func_name = nil)
    series = if func_name
               input_series(func_name, arrays)
             else
               arrays.flat_map { |arg| arg.is_a?(Array) && arg.first.is_a?(Array) ? arg : [arg] }
             end
    series_length!(series, func_name)
  end

  def series_length!(series, func_name)
    raise TALibError, "Expected input arrays" unless series.all?(Array)

    lengths = series.map(&:length).uniq
    raise TALibError, "Input arrays cannot be empty" unless lengths.fetch(0, 0).positive?
    raise TALibError, "#{func_name} input series must have equal lengths (got #{lengths.join(", ")})" unless lengths.one?
    raise TALibError, "Input arrays must contain only numbers" unless series.all? { |values| values.all?(Numeric) }

    lengths.first
  end
  private_class_method :series_length!

  def input_series(name, args)
    layout = function_info_map.fetch(name)[:input_names]
    input_shape_error!(name, layout) unless layout.size == args.size
    args.zip(layout).flat_map do |arg, fields|
      next [arg] unless fields.is_a?(Array)

      input_shape_error!(name, layout) unless arg.is_a?(Array) && arg.size == fields.size && arg.all?(Array)
      arg
    end
  end
  private_class_method :input_series

  def input_shape_error!(name, layout)
    args = layout.map { |input| input.is_a?(Array) ? "[#{input.join(", ")}]" : input }
    raise TALibError, "Expected TALibFFI.#{name.downcase}(#{args.join(", ")}) with optional parameters passed by keyword"
  end
  private_class_method :input_shape_error!

  def validate_options!(name, options, keywords)
    options.each do |key, value|
      unless keywords.key?(key)
        allowed = keywords.empty? ? "no keywords accepted" : "available keywords: #{keywords.keys.join(", ")}"
        raise TALibError, "#{name} unknown keyword #{key.inspect} (#{allowed})"
      end
      raise TALibError, "#{name} keyword #{key.inspect} requires a number" unless value.is_a?(Numeric)
    end
  end
  private_class_method :validate_options!

  # Gets a function handle for a given function name
  #
  # @param func_name [String] The name of the function
  # @return [Fiddle::Pointer] Pointer to function handle
  def get_function_handle(func_name)
    native_pointer { |slot| TA_GetFuncHandle(func_name, slot) }
  end

  # Creates a parameter holder for a function
  #
  # @param handle_ptr [Fiddle::Pointer] Function handle pointer
  # @return [Fiddle::Pointer] Pointer to parameter holder
  def create_parameter_holder(handle_ptr)
    native_pointer { |slot| TA_ParamHolderAlloc(handle_ptr, slot) }
  end

  # Sets up input parameters for a function call
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param input_arrays [Array<Array>] Input data arrays
  # @param func_name [String] Function name
  def setup_input_parameters(params_ptr, input_arrays, func_name, size: nil)
    func_info = function_info_map[func_name]
    input_arrays.each_with_index do |array, index|
      input_info = func_info[:inputs][index]
      ret_code = set_input_parameter(params_ptr, index, array, input_info, size: size)
      check_ta_return_code(ret_code)
    end
  end

  # Sets a single input parameter
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param index [Integer] Parameter index
  # @param array [Array] Input data array
  # @param input_info [Hash] Input parameter information
  # @return [Integer] TA-Lib return code
  def set_input_parameter(params_ptr, index, array, input_info, size: nil)
    case input_info["type"]
    when TA_PARAM_TYPE[:TA_Input_Real]
      bind_input(params_ptr, index, prepare_double_array(array, size: size)) { |ptr| TA_SetInputParamRealPtr(params_ptr, index, ptr) }
    when TA_PARAM_TYPE[:TA_Input_Integer]
      bind_input(params_ptr, index, prepare_integer_array(array, size: size)) { |ptr| TA_SetInputParamIntegerPtr(params_ptr, index, ptr) }
    when TA_PARAM_TYPE[:TA_Input_Price]
      setup_price_inputs(params_ptr, index, array, input_info["flags"], size: size)
    end
  end

  # TA-Lib borrows these pointers until TA_CallFunc returns. Keep the pointers
  # (and the packed Ruby strings they pin) alive on this particular holder.
  def bind_input(holder, index, buffer)
    status = yield(buffer)
    if status == TA_SUCCESS
      inputs = holder.instance_variable_get(:@ta_input_buffers) || holder.instance_variable_set(:@ta_input_buffers, [])
      inputs[index] = buffer
    end
    status
  end
  private_class_method :bind_input

  # Prepares a double array for TA-Lib input
  #
  # @param array [Array<Numeric>] Array of numbers to prepare
  # @return [Fiddle::Pointer] Pointer to prepared array
  def prepare_double_array(array, size: nil)
    packed_input(array.pack("d*"), Fiddle::SIZEOF_DOUBLE, size)
  end

  # Prepares an integer array for TA-Lib input
  #
  # @param array [Array<Numeric>] Array of numbers to prepare
  # @return [Fiddle::Pointer] Pointer to prepared array
  def prepare_integer_array(array, size: nil)
    packed_input(array.pack("i!*"), Fiddle::SIZEOF_INT, size)
  end

  # Check the actual snapshot too. Other Ruby threads can change an input
  # array between validation and packing while Fiddle releases the GVL.
  def packed_input(bytes, width, size)
    raise TALibError, "Input length changed during calculation" if size && bytes.bytesize != size * width

    Fiddle::Pointer[bytes]
  end
  private_class_method :packed_input

  # Sets up optional parameters for a function call
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param options [Hash] Optional parameters
  # @param func_name [String] Function name
  def setup_optional_parameters(params_ptr, options, func_name)
    keywords = function_info_map.fetch(func_name)[:keywords]
    options.each do |name, value|
      index, type = keywords.fetch(name)
      set_optional_parameter(params_ptr, index, value, type)
    end
  end

  # Sets a single optional parameter
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param index [Integer] Parameter index
  # @param value [Numeric] Parameter value
  # @param type [Integer] Parameter type
  def set_optional_parameter(params_ptr, index, value, type)
    case type
    when TA_PARAM_TYPE[:TA_OptInput_RealRange], TA_PARAM_TYPE[:TA_OptInput_RealList]
      ret_code = TA_SetOptInputParamReal(params_ptr, index, value)
    when TA_PARAM_TYPE[:TA_OptInput_IntegerRange], TA_PARAM_TYPE[:TA_OptInput_IntegerList]
      ret_code = TA_SetOptInputParamInteger(params_ptr, index, value)
    end
    check_ta_return_code(ret_code)
  end

  # Calculates function results
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param input_arrays [Array] Input data
  # @param func_name [String] Function name
  # @return [Array, Hash] Function results
  def calculate_results(params_ptr, input_arrays, func_name, input_size: validate_inputs!(input_arrays, func_name))
    out_begin = [0].pack("i!")
    out_size = [0].pack("i!")
    buffers = setup_output_buffers(params_ptr, input_size, func_name)
    check_ta_return_code(TA_CallFunc(params_ptr, 0, input_size - 1, out_begin, out_size))
    count = out_size.unpack1("i!")
    raise TALibError, "Invalid output count #{count} for #{func_name}" unless count.between?(0, input_size)

    format_output_results(buffers, count, func_name)
  end

  # Sets up output buffers for function results
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param size [Integer] Size of output buffer
  # @param func_name [String] Function name
  # @return [Array<Fiddle::Pointer>] Array of output buffer pointers
  def setup_output_buffers(params_ptr, size, func_name)
    function_info_map.fetch(func_name)[:output_layout].map.with_index do |(_format, width, setter), index|
      ptr = Fiddle::Pointer["\0".b * (size * width)]
      check_ta_return_code(public_send(setter, params_ptr, index, ptr))
      ptr
    end
  end

  # Formats output results from TA-Lib function
  #
  # @param output_ptrs [Array<Fiddle::Pointer>] Array of output buffer pointers
  # @param size [Integer] Size of output data
  # @param func_name [String] Function name
  # @return [Array, Hash] Formatted results
  def format_output_results(output_ptrs, size, func_name)
    info = function_info_map.fetch(func_name)
    results = output_ptrs.zip(info[:output_layout]).map do |ptr, (format, width, _)|
      ptr.to_s(size * width).unpack("#{format}*")
    end
    results.one? ? results.first : info[:output_names].zip(results).to_h
  end

  # Gets XML description of all TA-Lib functions
  #
  # @return [String] XML function descriptions
  def function_description_xml
    TA_FunctionDescriptionXML().to_s
  end

  # Gets or builds the function information map
  #
  # @return [Hash] Map of function information
  def function_info_map
    @function_info_map ||= build_function_info_map
  end

  # Builds a map of function information for all functions
  #
  # @return [Hash] Map of function information
  def build_function_info_map
    info_map = {}
    each_function do |func_info|
      info_map[func_info["name"].to_s] = function_parameters(func_info)
    end
    info_map
  end

  def function_parameters(info)
    inputs = collect_input_info(info)
    options = collect_opt_input_info(info)
    outputs = collect_output_info(info)
    {
      info: info, handle: info["handle"], inputs: inputs, opt_inputs: options, outputs: outputs,
      input_names: inputs.map { |input| input_name(input) },
      keywords: keyword_index(options),
      output_layout: outputs.map { |output| OUTPUT_LAYOUTS.fetch(output["type"]) },
      output_names: outputs.map { |output| parameter_key(output) }
    }
  end
  private_class_method :function_parameters

  def keyword_index(options)
    options.each_with_index.to_h { |option, index| [parameter_key(option), [index, option["type"]]] }
  end
  private_class_method :keyword_index

  def parameter_key(parameter)
    normalize_parameter_name(parameter["paramName"].to_s).to_sym
  end
  private_class_method :parameter_key
  def input_name(input)
    return normalize_parameter_name(input["paramName"].to_s) unless input["type"] == TA_PARAM_TYPE[:TA_Input_Price]

    PRICE_FIELDS.values_at(*price_indexes(input["flags"]))
  end
  private_class_method :input_name

  def price_indexes(flags)
    raise TALibError, "Unsupported TA-Lib price flags #{flags}" unless (flags >> PRICE_FIELDS.size).zero?

    PRICE_FIELDS.each_index.select { |i| flags.anybits?(1 << i) }
  end
  private_class_method :price_indexes

  # Collects input parameter information for a function
  #
  # @param func_info [Fiddle::CStructEntity] Function information
  # @return [Array<Fiddle::CStructEntity>] Array of input parameter information
  def collect_input_info(func_info)
    handle = func_info["handle"]
    func_info["nbInput"].times.map do |index|
      TA_InputParameterInfo.new(native_pointer { |slot| TA_GetInputParameterInfo(handle, index, slot) })
    end
  end

  # Collects optional input parameter information for a function
  #
  # @param func_info [Fiddle::CStructEntity] Function information
  # @return [Array<Fiddle::CStructEntity>] Array of optional input parameter information
  def collect_opt_input_info(func_info)
    handle = func_info["handle"]
    func_info["nbOptInput"].times.map do |index|
      TA_OptInputParameterInfo.new(native_pointer { |slot| TA_GetOptInputParameterInfo(handle, index, slot) })
    end
  end

  # Collects output parameter information for a function
  #
  # @param func_info [Fiddle::CStructEntity] Function information
  # @return [Array<Fiddle::CStructEntity>] Array of output parameter information
  def collect_output_info(func_info)
    handle = func_info["handle"]
    func_info["nbOutput"].times.map do |index|
      TA_OutputParameterInfo.new(native_pointer { |slot| TA_GetOutputParameterInfo(handle, index, slot) })
    end
  end

  # Generates Ruby methods for all TA-Lib functions
  #
  # This method iterates through all available TA-Lib functions and creates
  # corresponding Ruby methods with proper documentation.
  def generate_ta_functions
    function_info_map.each_key { |name| define_ta_function(name.downcase, name) }
  end

  # Normalizes parameter names to Ruby style
  #
  # @param name [String] Parameter name to normalize
  # @return [String] Normalized parameter name
  def normalize_parameter_name(name)
    name.sub(/^(optIn|outReal|outInteger|out|in)/, "")
        .gsub(/::/, "/")
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr("-", "_")
        .downcase
  end

  # Checks TA-Lib return codes and raises appropriate errors
  #
  # @param code [Integer] TA-Lib return code
  # @raise [TALibError] If the return code indicates an error
  def check_ta_return_code(code) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
    return if code == TA_SUCCESS

    error_message = case code
                    when TA_LIB_NOT_INITIALIZE
                      "TA-Lib not initialized, please call TA_Initialize first"
                    when TA_BAD_PARAM
                      "Bad parameter, please check input parameters"
                    when TA_ALLOC_ERR
                      "Memory allocation error, possibly insufficient memory"
                    when TA_GROUP_NOT_FOUND
                      "Function group not found"
                    when TA_FUNC_NOT_FOUND
                      "Function not found"
                    when TA_INVALID_HANDLE
                      "Invalid handle"
                    when TA_INVALID_PARAM_HOLDER
                      "Invalid parameter holder"
                    when TA_INVALID_PARAM_HOLDER_TYPE
                      "Invalid parameter holder type"
                    when TA_INVALID_PARAM_FUNCTION
                      "Invalid parameter function"
                    when TA_INPUT_NOT_ALL_INITIALIZE
                      "Input parameters not fully initialized"
                    when TA_OUTPUT_NOT_ALL_INITIALIZE
                      "Output parameters not fully initialized"
                    when TA_OUT_OF_RANGE_START_INDEX
                      "Start index out of range"
                    when TA_OUT_OF_RANGE_END_INDEX
                      "End index out of range"
                    when TA_INVALID_LIST_TYPE
                      "Invalid list type"
                    when TA_BAD_OBJECT
                      "Invalid object"
                    when TA_NOT_SUPPORTED
                      "Operation not supported"
                    when TA_INTERNAL_ERROR
                      "TA-Lib internal error"
                    when TA_UNKNOWN_ERR
                      "Unknown error"
                    else
                      "Undefined TA-Lib error (Error code: #{code})"
                    end

    raise TALibError, error_message
  end

  # Initializes the TA-Lib library
  def initialize_ta_lib
    return if @initialized

    ret_code = TA_Initialize()
    check_ta_return_code(ret_code)
    at_exit { TA_Shutdown() }
    @initialized = true
  end

  # Defines a TA-Lib function as a Ruby method with documentation
  #
  # @param method_name [String] Name of the Ruby method to define
  # @param func_name [String] Name of the TA-Lib function
  def define_ta_function(method_name, func_name)
    define_singleton_method(method_name) do |*args|
      call_func(func_name, args)
    end
  end

  # Sets up price inputs for functions that take price data
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param index [Integer] Parameter index
  # @param price_data [Array] Price data array
  # @param flags [Integer] Input flags
  def setup_price_inputs(params_ptr, index, price_data, flags, size: nil)
    pointers = Array.new(PRICE_FIELDS.size)
    price_indexes(flags).zip(price_data) { |slot, series| pointers[slot] = prepare_double_array(series, size: size) }
    bind_input(params_ptr, index, pointers) { |prices| TA_SetInputParamPricePtr(params_ptr, index, *prices) }
  end

  initialize_ta_lib
  generate_ta_functions

  # Placeholder for generated TA-Lib function documentation.
  # Available functions and their defaults depend on the installed C library.
  # Run: rake yard
  class << self
    ### GENERATED DOCUMENTATION START ###
    # @!method ac(price_hl, fast_period: 5.0, slow_period: 34.0, signal_period: 5.0)
    # Accelerator/Decelerator Oscillator
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param fast_period [Integer]  Period of the fast MA (default: 5.0)
    # @param slow_period [Integer]  Period of the slow MA (default: 34.0)
    # @param signal_period [Integer]  Smoothing for the signal line (period length) (default: 5.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method accbands(price_hlc, time_period: 20.0)
    # Acceleration Bands
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 20.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :upper_band  Output values
    # @option result [Array<Float>] :middle_band  Output values
    # @option result [Array<Float>] :lower_band  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method acos(real)
    # Vector Trigonometric ACos
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ad(price_hlcv)
    # Chaikin A/D Line
    #
    # @param price_hlcv [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close, volume
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method add(real0, real1)
    # Vector Arithmetic Add
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method adosc(price_hlcv, fast_period: 3.0, slow_period: 10.0)
    # Chaikin A/D Oscillator
    #
    # @param price_hlcv [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close, volume
    # @param fast_period [Integer]  Period of the fast MA (default: 3.0)
    # @param slow_period [Integer]  Period of the slow MA (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method adr(price_hl, time_period: 14.0)
    # Average Day Range
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method adx(price_hlc, time_period: 14.0)
    # Average Directional Movement Index
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method adxr(price_hlc, time_period: 14.0)
    # Average Directional Movement Index Rating
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method alma(real, time_period: 9.0, sigma: 6.0, offset: 0.85)
    # Arnaud Legoux Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 9.0)
    # @param sigma [Float]  Gaussian width divisor (default: 6.0)
    # @param offset [Float]  Position of the peak weight (default: 0.85)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ao(price_hl, fast_period: 5.0, slow_period: 34.0)
    # Awesome Oscillator
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param fast_period [Integer]  Period of the fast MA (default: 5.0)
    # @param slow_period [Integer]  Period of the slow MA (default: 34.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method apo(real, fast_period: 12.0, slow_period: 26.0, ma_type: 1.0)
    # Absolute Price Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Period of the fast MA (default: 12.0)
    # @param slow_period [Integer]  Period of the slow MA (default: 26.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 1.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method aroon(price_hl, time_period: 14.0)
    # Aroon
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :aroon_down  Output values
    # @option result [Array<Float>] :aroon_up  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method aroonosc(price_hl, time_period: 14.0)
    # Aroon Oscillator
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method asi(price_ohlc, limit_move: 3.0)
    # Wilder Accumulative Swing Index
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param limit_move [Float]  Largest one-bar price move the index is scaled against, in price units (default: 3.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method asin(real)
    # Vector Trigonometric ASin
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method atan(real)
    # Vector Trigonometric ATan
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method atr(price_hlc, time_period: 14.0)
    # Average True Range
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method avgdev(real, time_period: 14.0)
    # Average Deviation
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method avgprice(price_ohlc)
    # Average Price
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method bbands(real, time_period: 20.0, nb_dev_up: 2.0, nb_dev_dn: 2.0, ma_type: 0.0)
    # Bollinger Bands
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 20.0)
    # @param nb_dev_up [Float]  Deviation multiplier for upper band (default: 2.0)
    # @param nb_dev_dn [Float]  Deviation multiplier for lower band (default: 2.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :upper_band  Output values
    # @option result [Array<Float>] :middle_band  Output values
    # @option result [Array<Float>] :lower_band  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method bbw(real, time_period: 20.0, nb_dev_up: 2.0, nb_dev_dn: 2.0, ma_type: 0.0)
    # Bollinger BandWidth
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 20.0)
    # @param nb_dev_up [Float]  Deviation multiplier for upper band (default: 2.0)
    # @param nb_dev_dn [Float]  Deviation multiplier for lower band (default: 2.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method beta(real0, real1, time_period: 5.0)
    # Beta
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 5.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method bop(price_ohlc)
    # Balance Of Power
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cci(price_hlc, time_period: 14.0)
    # Commodity Channel Index
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdl2crows(price_ohlc)
    # Two Crows
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdl3blackcrows(price_ohlc)
    # Three Black Crows
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdl3inside(price_ohlc)
    # Three Inside Up/Down
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdl3linestrike(price_ohlc)
    # Three-Line Strike
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdl3outside(price_ohlc)
    # Three Outside Up/Down
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdl3starsinsouth(price_ohlc)
    # Three Stars In The South
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdl3whitesoldiers(price_ohlc)
    # Three Advancing White Soldiers
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlabandonedbaby(price_ohlc, penetration: 0.3)
    # Abandoned Baby
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param penetration [Float]  Percentage of penetration of a candle within another candle (default: 0.3)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdladvanceblock(price_ohlc)
    # Advance Block
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlbelthold(price_ohlc)
    # Belt-hold
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlbreakaway(price_ohlc)
    # Breakaway
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlclosingmarubozu(price_ohlc)
    # Closing Marubozu
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlconcealbabyswall(price_ohlc)
    # Concealing Baby Swallow
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlcounterattack(price_ohlc)
    # Counterattack
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdldarkcloudcover(price_ohlc, penetration: 0.5)
    # Dark Cloud Cover
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param penetration [Float]  Percentage of penetration of a candle within another candle (default: 0.5)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdldoji(price_ohlc)
    # Doji
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdldojistar(price_ohlc)
    # Doji Star
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdldragonflydoji(price_ohlc)
    # Dragonfly Doji
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlengulfing(price_ohlc)
    # Engulfing Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdleveningdojistar(price_ohlc, penetration: 0.3)
    # Evening Doji Star
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param penetration [Float]  Percentage of penetration of a candle within another candle (default: 0.3)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdleveningstar(price_ohlc, penetration: 0.3)
    # Evening Star
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param penetration [Float]  Percentage of penetration of a candle within another candle (default: 0.3)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlgapsidesidewhite(price_ohlc)
    # Up/Down-gap side-by-side white lines
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlgravestonedoji(price_ohlc)
    # Gravestone Doji
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlhammer(price_ohlc)
    # Hammer
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlhangingman(price_ohlc)
    # Hanging Man
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlharami(price_ohlc)
    # Harami Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlharamicross(price_ohlc)
    # Harami Cross Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlhighwave(price_ohlc)
    # High-Wave Candle
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlhikkake(price_ohlc)
    # Hikkake Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlhikkakemod(price_ohlc)
    # Modified Hikkake Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlhomingpigeon(price_ohlc)
    # Homing Pigeon
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlidentical3crows(price_ohlc)
    # Identical Three Crows
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlinneck(price_ohlc)
    # In-Neck Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlinvertedhammer(price_ohlc)
    # Inverted Hammer
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlkicking(price_ohlc)
    # Kicking
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlkickingbylength(price_ohlc)
    # Kicking - bull/bear determined by the longer marubozu
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlladderbottom(price_ohlc)
    # Ladder Bottom
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdllongleggeddoji(price_ohlc)
    # Long Legged Doji
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdllongline(price_ohlc)
    # Long Line Candle
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlmarubozu(price_ohlc)
    # Marubozu
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlmatchinglow(price_ohlc)
    # Matching Low
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlmathold(price_ohlc, penetration: 0.5)
    # Mat Hold
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param penetration [Float]  Percentage of penetration of a candle within another candle (default: 0.5)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlmorningdojistar(price_ohlc, penetration: 0.3)
    # Morning Doji Star
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param penetration [Float]  Percentage of penetration of a candle within another candle (default: 0.3)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlmorningstar(price_ohlc, penetration: 0.3)
    # Morning Star
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param penetration [Float]  Percentage of penetration of a candle within another candle (default: 0.3)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlonneck(price_ohlc)
    # On-Neck Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlpiercing(price_ohlc)
    # Piercing Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlrickshawman(price_ohlc)
    # Rickshaw Man
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlrisefall3methods(price_ohlc)
    # Rising/Falling Three Methods
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlseparatinglines(price_ohlc)
    # Separating Lines
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlshootingstar(price_ohlc)
    # Shooting Star
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlshortline(price_ohlc)
    # Short Line Candle
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlspinningtop(price_ohlc)
    # Spinning Top
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlstalledpattern(price_ohlc)
    # Stalled Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlsticksandwich(price_ohlc)
    # Stick Sandwich
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdltakuri(price_ohlc)
    # Takuri (Dragonfly Doji with very long lower shadow)
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdltasukigap(price_ohlc)
    # Tasuki Gap
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlthrusting(price_ohlc)
    # Thrusting Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdltristar(price_ohlc)
    # Tristar Pattern
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlunique3river(price_ohlc)
    # Unique 3 River
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlupsidegap2crows(price_ohlc)
    # Upside Gap Two Crows
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cdlxsidegap3methods(price_ohlc)
    # Upside/Downside Gap Three Methods
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ceil(real)
    # Vector Ceil
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cg(real, time_period: 10.0)
    # Center of Gravity Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of bars in the window (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method chop(price_hlc, time_period: 14.0)
    # Choppiness Index
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method choptr(price_hlc, time_period: 14.0)
    # Choppiness Index (True Range Box)
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cksp(price_hlc, time_period: 10.0, multiplier: 1.0, stop_period: 9.0)
    # Chande Kroll Stop
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  ATR and extreme window (default: 10.0)
    # @param multiplier [Float]  ATR multiplier (default: 1.0)
    # @param stop_period [Integer]  Stop window (default: 9.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :high_stop  Output values
    # @option result [Array<Float>] :low_stop  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method cmf(price_hlcv, time_period: 20.0)
    # Chaikin Money Flow
    #
    # @param price_hlcv [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close, volume
    # @param time_period [Integer]  Time period (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cmo(real, time_period: 14.0)
    # Chande Momentum Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cmou(real, time_period: 14.0)
    # Chande Momentum Oscillator (Unsmoothed)
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method coppock(real, wma_period: 10.0, roc1_period: 11.0, roc2_period: 14.0)
    # Coppock Curve
    #
    # @param real [Array<Float>]  Input values
    # @param wma_period [Integer]  Smoothing period for the ROC sum (default: 10.0)
    # @param roc1_period [Integer]  Short rate-of-change period (default: 11.0)
    # @param roc2_period [Integer]  Long rate-of-change period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method correl(real0, real1, time_period: 30.0)
    # Pearson's Correlation Coefficient (r)
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cos(real)
    # Vector Trigonometric Cos
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cosh(real)
    # Vector Trigonometric Cosh
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method crsi(real, time_period: 3.0, streak_period: 2.0, rank_period: 100.0)
    # Connors Relative Strength Index
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 3.0)
    # @param streak_period [Integer]  Time period of the RSI of the up/down streak (default: 2.0)
    # @param rank_period [Integer]  Number of previous one-bar returns the current one is ranked against (default: 100.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cti(real, time_period: 20.0)
    # Correlation Trend Indicator
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of bars correlated against the ramp (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cumsum(real)
    # Cumulative Sum
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method cvi(price_hl, time_period: 10.0, roc_period: 10.0)
    # Chaikin's Volatility
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Period of the EMA smoothing the high-low spread (default: 10.0)
    # @param roc_period [Integer]  Number of bars the rate of change reaches back (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method dema(real, time_period: 30.0)
    # Double Exponential Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method div(real0, real1)
    # Vector Arithmetic Div
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method donchian(price_hl, time_period: 20.0)
    # Donchian Channels
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period (default: 20.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :upper_band  Output values
    # @option result [Array<Float>] :middle_band  Output values
    # @option result [Array<Float>] :lower_band  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method dosc(real, time_period: 14.0, first_period: 5.0, second_period: 3.0, signal_period: 9.0)
    # Derivative Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Period of the RSI (default: 14.0)
    # @param first_period [Integer]  Period of the first smoothing, applied to the RSI (default: 5.0)
    # @param second_period [Integer]  Period of the second smoothing, applied to the first (default: 3.0)
    # @param signal_period [Integer]  Period of the simple average subtracted from the smoothed line (default: 9.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method dpo(real, time_period: 20.0)
    # Detrended Price Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method dx(price_hlc, time_period: 14.0)
    # Directional Movement Index
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method efi(price_cv, time_period: 13.0)
    # Elder's Force Index
    #
    # @param price_cv [Array(Array<Float>, Array<Float>)]  Required price arrays: close, volume
    # @param time_period [Integer]  Time period (default: 13.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ema(real, time_period: 30.0)
    # Exponential Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method emv(price_hlv, time_period: 14.0, volume_divisor: 10000.0)
    # Arms Ease of Movement
    #
    # @param price_hlv [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, volume
    # @param time_period [Integer]  Bars in the SMA of the one-bar values (1 = unsmoothed) (default: 14.0)
    # @param volume_divisor [Float]  Volume is divided by this before forming the box ratio (default: 10000.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method er(real, time_period: 10.0)
    # Kaufman Efficiency Ratio
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of one-bar changes in the path sum (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method eri(price_hlc, time_period: 13.0)
    # Elder Ray Index (Bull Power / Bear Power)
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Number of bars in the EMA of close (default: 13.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :bull_power  Output values
    # @option result [Array<Float>] :bear_power  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method exp(real)
    # Vector Arithmetic Exp
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method fisher(price_hl, time_period: 10.0)
    # Fisher Transform
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period (default: 10.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :fisher  Output values
    # @option result [Array<Float>] :trigger  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method floor(real)
    # Vector Floor
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method fosc(real, time_period: 5.0)
    # Forecast Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 5.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method fractal(price_hl, left_bars: 2.0, right_bars: 2.0)
    # Williams Fractal
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param left_bars [Integer]  Number of bars required to be lower/higher before the pivot (default: 2.0)
    # @param right_bars [Integer]  Number of bars required to be lower/higher after the pivot (default: 2.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Integer>] :swing_high  Output values
    # @option result [Array<Integer>] :swing_low  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method frama(price_hl, time_period: 16.0)
    # Fractal Adaptive Moving Average
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Number of bars, even; the window is split into two halves of optInTimePeriod/2 bars (default: 16.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ha(price_ohlc)
    # Heikin-Ashi Candles
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :ha_open  Output values
    # @option result [Array<Float>] :ha_high  Output values
    # @option result [Array<Float>] :ha_low  Output values
    # @option result [Array<Float>] :ha_close  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method hma(real, time_period: 20.0)
    # Hull Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ht_dcperiod(real)
    # Hilbert Transform - Dominant Cycle Period
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ht_dcphase(real)
    # Hilbert Transform - Dominant Cycle Phase
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ht_phasor(real)
    # Hilbert Transform - Phasor Components
    #
    # @param real [Array<Float>]  Input values
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :in_phase  Output values
    # @option result [Array<Float>] :quadrature  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method ht_sine(real)
    # Hilbert Transform - SineWave
    #
    # @param real [Array<Float>]  Input values
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :sine  Output values
    # @option result [Array<Float>] :lead_sine  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method ht_trendline(real)
    # Hilbert Transform - Instantaneous Trendline
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ht_trendmode(real)
    # Hilbert Transform - Trend vs Cycle Mode
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ibs(price_hlc)
    # Internal Bar Strength
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ichimoku(price_hl, tenkan_period: 9.0, kijun_period: 26.0, senkou_b_period: 52.0)
    # Ichimoku Kinko Hyo
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param tenkan_period [Integer]  Period of the conversion line (default: 9.0)
    # @param kijun_period [Integer]  Period of the base line, and the forward shift of the two spans (default: 26.0)
    # @param senkou_b_period [Integer]  Period of the second leading span (default: 52.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :tenkan_sen  Output values
    # @option result [Array<Float>] :kijun_sen  Output values
    # @option result [Array<Float>] :senkou_span_a  Output values
    # @option result [Array<Float>] :senkou_span_b  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method imi(price_oc, time_period: 14.0)
    # Intraday Momentum Index
    #
    # @param price_oc [Array(Array<Float>, Array<Float>)]  Required price arrays: open, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method kama(real, time_period: 30.0)
    # Kaufman Adaptive Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method kc(price_hlc, time_period: 20.0, atr_period: 10.0, nb_dev: 2.0)
    # Keltner Channels
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period for the typical price moving average (default: 20.0)
    # @param atr_period [Integer]  Time period for the Average True Range (default: 10.0)
    # @param nb_dev [Float]  Multiplier applied to the Average True Range (default: 2.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :upper_band  Output values
    # @option result [Array<Float>] :middle_band  Output values
    # @option result [Array<Float>] :lower_band  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method kdj(price_hlc, fast_k_period: 9.0, slow_k_period: 3.0, slow_k_ma_type: 13.0, slow_d_period: 3.0, slow_d_ma_type: 13.0)
    # KDJ Stochastic
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param fast_k_period [Integer]  Time period for building the Fast-K line (default: 9.0)
    # @param slow_k_period [Integer]  Smoothing for making the Slow-K line. Usually set to 3 (default: 3.0)
    # @param slow_k_ma_type [Integer]  Type of Moving Average for Slow-K (default: 13.0)
    # @param slow_d_period [Integer]  Smoothing for making the Slow-D line (default: 3.0)
    # @param slow_d_ma_type [Integer]  Type of Moving Average for Slow-D (default: 13.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :k  Output values
    # @option result [Array<Float>] :d  Output values
    # @option result [Array<Float>] :j  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method kst(real, roc1_period: 10.0, roc2_period: 15.0, roc3_period: 20.0, roc4_period: 30.0, sma1_period: 10.0, sma2_period: 10.0, sma3_period: 10.0, sma4_period: 15.0, signal_period: 9.0)
    # Know Sure Thing (Pring)
    #
    # @param real [Array<Float>]  Input values
    # @param roc1_period [Integer]  Rate-of-change period of leg 1 (default: 10.0)
    # @param roc2_period [Integer]  Rate-of-change period of leg 2 (default: 15.0)
    # @param roc3_period [Integer]  Rate-of-change period of leg 3 (default: 20.0)
    # @param roc4_period [Integer]  Rate-of-change period of leg 4 (default: 30.0)
    # @param sma1_period [Integer]  Smoothing period of leg 1 (default: 10.0)
    # @param sma2_period [Integer]  Smoothing period of leg 2 (default: 10.0)
    # @param sma3_period [Integer]  Smoothing period of leg 3 (default: 10.0)
    # @param sma4_period [Integer]  Smoothing period of leg 4 (default: 15.0)
    # @param signal_period [Integer]  Smoothing period of the signal line (default: 9.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :kst  Output values
    # @option result [Array<Float>] :kst_signal  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method kstext(real, roc1_period: 10.0, roc2_period: 15.0, roc3_period: 20.0, roc4_period: 30.0, ma1_period: 10.0, ma2_period: 10.0, ma3_period: 10.0, ma4_period: 15.0, signal_period: 9.0, rocma_type: 0.0, signal_ma_type: 0.0)
    # Know Sure Thing with controllable MA type
    #
    # @param real [Array<Float>]  Input values
    # @param roc1_period [Integer]  Rate-of-change period of leg 1 (default: 10.0)
    # @param roc2_period [Integer]  Rate-of-change period of leg 2 (default: 15.0)
    # @param roc3_period [Integer]  Rate-of-change period of leg 3 (default: 20.0)
    # @param roc4_period [Integer]  Rate-of-change period of leg 4 (default: 30.0)
    # @param ma1_period [Integer]  Smoothing period of leg 1 (default: 10.0)
    # @param ma2_period [Integer]  Smoothing period of leg 2 (default: 10.0)
    # @param ma3_period [Integer]  Smoothing period of leg 3 (default: 10.0)
    # @param ma4_period [Integer]  Smoothing period of leg 4 (default: 15.0)
    # @param signal_period [Integer]  Smoothing period of the signal line (default: 9.0)
    # @param rocma_type [Integer]  Type of Moving Average smoothing the four legs (default: 0.0)
    # @param signal_ma_type [Integer]  Type of Moving Average for signal line (default: 0.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :kst  Output values
    # @option result [Array<Float>] :kst_signal  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method kurtosis(real, time_period: 30.0)
    # Rolling Excess Kurtosis
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method kvo(price_hlcv, fast_period: 34.0, slow_period: 55.0, signal_period: 13.0)
    # Klinger Volume Oscillator
    #
    # @param price_hlcv [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close, volume
    # @param fast_period [Integer]  Period of the faster smoothing of the volume force (default: 34.0)
    # @param slow_period [Integer]  Period of the slower smoothing of the volume force (default: 55.0)
    # @param signal_period [Integer]  Smoothing for the trigger line (default: 13.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :kvo  Output values
    # @option result [Array<Float>] :kvo_signal  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method linearreg(real, time_period: 14.0)
    # Linear Regression
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method linearreg_angle(real, time_period: 14.0)
    # Linear Regression Angle
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method linearreg_intercept(real, time_period: 14.0)
    # Linear Regression Intercept
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method linearreg_slope(real, time_period: 14.0)
    # Linear Regression Slope
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ln(real)
    # Vector Log Natural
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method log10(real)
    # Vector Log10
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ma(real, time_period: 30.0, ma_type: 0.0)
    # Moving average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method macd(real, fast_period: 12.0, slow_period: 26.0, signal_period: 9.0)
    # Moving Average Convergence/Divergence
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Period of the fast MA (default: 12.0)
    # @param slow_period [Integer]  Period of the slow MA (default: 26.0)
    # @param signal_period [Integer]  Smoothing for the signal line (period length) (default: 9.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :macd  Output values
    # @option result [Array<Float>] :macd_signal  Output values
    # @option result [Array<Float>] :macd_hist  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method macdext(real, fast_period: 12.0, fast_ma_type: 0.0, slow_period: 26.0, slow_ma_type: 0.0, signal_period: 9.0, signal_ma_type: 0.0)
    # MACD with controllable MA type
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Period of the fast MA (default: 12.0)
    # @param fast_ma_type [Integer]  Type of Moving Average for fast MA (default: 0.0)
    # @param slow_period [Integer]  Period of the slow MA (default: 26.0)
    # @param slow_ma_type [Integer]  Type of Moving Average for slow MA (default: 0.0)
    # @param signal_period [Integer]  Smoothing for the signal line (period length) (default: 9.0)
    # @param signal_ma_type [Integer]  Type of Moving Average for signal line (default: 0.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :macd  Output values
    # @option result [Array<Float>] :macd_signal  Output values
    # @option result [Array<Float>] :macd_hist  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method macdfix(real, signal_period: 9.0)
    # Moving Average Convergence/Divergence Fix 12/26
    #
    # @param real [Array<Float>]  Input values
    # @param signal_period [Integer]  Smoothing for the signal line (period length) (default: 9.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :macd  Output values
    # @option result [Array<Float>] :macd_signal  Output values
    # @option result [Array<Float>] :macd_hist  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method mama(real, fast_limit: 0.5, slow_limit: 0.05)
    # MESA Adaptive Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param fast_limit [Float]  Upper limit use in the adaptive algorithm (default: 0.5)
    # @param slow_limit [Float]  Lower limit use in the adaptive algorithm (default: 0.05)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :mama  Output values
    # @option result [Array<Float>] :fama  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method marketfi(price_hlv)
    # Market Facilitation Index
    #
    # @param price_hlv [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, volume
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method massi(price_hl, fast_period: 9.0, slow_period: 25.0)
    # Mass Index
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param fast_period [Integer]  Period of both exponential averages of the high-low range (default: 9.0)
    # @param slow_period [Integer]  Number of bars the ratio is summed over (default: 25.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method mavp(real, periods, min_period: 2.0, max_period: 30.0, ma_type: 0.0)
    # Moving average with variable period
    #
    # @param real [Array<Float>]  Input values
    # @param periods [Array<Float>]  Input values
    # @param min_period [Integer]  Value less than minimum will be changed to Minimum period (default: 2.0)
    # @param max_period [Integer]  Value higher than maximum will be changed to Maximum period (default: 30.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method max(real, time_period: 30.0)
    # Highest value over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method maxindex(real, time_period: 30.0)
    # Index of highest value over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method mcgd(real, time_period: 14.0)
    # McGinley Dynamic
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method median(real, time_period: 30.0)
    # Rolling Median
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of bars in the window (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method medprice(price_hl)
    # Median Price
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method mfi(price_hlcv, time_period: 14.0)
    # Money Flow Index
    #
    # @param price_hlcv [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close, volume
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method midpoint(real, time_period: 14.0)
    # MidPoint over period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method midprice(price_hl, time_period: 14.0)
    # Midpoint Price over period
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method min(real, time_period: 30.0)
    # Lowest value over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method minindex(real, time_period: 30.0)
    # Index of lowest value over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method minmax(real, time_period: 30.0)
    # Lowest and highest values over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :min  Output values
    # @option result [Array<Float>] :max  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method minmaxindex(real, time_period: 30.0)
    # Indexes of lowest and highest values over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Integer>] :min_idx  Output values
    # @option result [Array<Integer>] :max_idx  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method minus_di(price_hlc, time_period: 14.0)
    # Minus Directional Indicator
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method minus_dm(price_hl, time_period: 14.0)
    # Minus Directional Movement
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method mom(real, time_period: 10.0)
    # Momentum
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method mult(real0, real1)
    # Vector Arithmetic Mult
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method natr(price_hlc, time_period: 14.0)
    # Normalized Average True Range
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method nvi(price_cv)
    # Negative Volume Index
    #
    # @param price_cv [Array(Array<Float>, Array<Float>)]  Required price arrays: close, volume
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method obv(real, price_v)
    # On Balance Volume
    #
    # @param real [Array<Float>]  Input values
    # @param price_v [Array(Array<Float>)]  Required price arrays: volume
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method percentb(real, time_period: 20.0, nb_dev_up: 2.0, nb_dev_dn: 2.0, ma_type: 0.0)
    # Bollinger Bands %B
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 20.0)
    # @param nb_dev_up [Float]  Deviation multiplier for upper band (default: 2.0)
    # @param nb_dev_dn [Float]  Deviation multiplier for lower band (default: 2.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method percentile(real, time_period: 100.0, percentile: 50.0)
    # Percentile (nearest rank)
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of bars in the window (default: 100.0)
    # @param percentile [Float]  Percentile to report (default: 50.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method percentrank(real, time_period: 100.0)
    # Percent Rank
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 100.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method plus_di(price_hlc, time_period: 14.0)
    # Plus Directional Indicator
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method plus_dm(price_hl, time_period: 14.0)
    # Plus Directional Movement
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ppo(real, fast_period: 12.0, slow_period: 26.0, ma_type: 1.0)
    # Percentage Price Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Period of the fast MA (default: 12.0)
    # @param slow_period [Integer]  Period of the slow MA (default: 26.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 1.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method pso(price_hlc, fast_k_period: 8.0, ema_period: 5.0)
    # Premier Stochastic Oscillator
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param fast_k_period [Integer]  Time period for building the Fast-K line (default: 8.0)
    # @param ema_period [Integer]  Period of each of the two smoothing passes (default: 5.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method pvi(price_cv)
    # Positive Volume Index
    #
    # @param price_cv [Array(Array<Float>, Array<Float>)]  Required price arrays: close, volume
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method pvo(price_v, fast_period: 12.0, slow_period: 26.0, ma_type: 1.0)
    # Percentage Volume Oscillator
    #
    # @param price_v [Array(Array<Float>)]  Required price arrays: volume
    # @param fast_period [Integer]  Period of the fast MA (default: 12.0)
    # @param slow_period [Integer]  Period of the slow MA (default: 26.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 1.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method pvt(price_cv)
    # Price Volume Trend
    #
    # @param price_cv [Array(Array<Float>, Array<Float>)]  Required price arrays: close, volume
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method qstick(price_oc, time_period: 10.0)
    # Qstick
    #
    # @param price_oc [Array(Array<Float>, Array<Float>)]  Required price arrays: open, close
    # @param time_period [Integer]  Time period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rma(real, time_period: 30.0)
    # Wilder's Smoothed Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method roc(real, time_period: 10.0)
    # Rate of change : ((price/prevPrice)-1)*100
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rocp(real, time_period: 10.0)
    # Rate of change Percentage: (price-prevPrice)/prevPrice
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rocr(real, time_period: 10.0)
    # Rate of change ratio: (price/prevPrice)
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rocr100(real, time_period: 10.0)
    # Rate of change ratio 100 scale: (price/prevPrice)*100
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rogerssatchell(price_ohlc, time_period: 10.0, annualization: 252.0)
    # Rogers-Satchell Volatility
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param time_period [Integer]  Number of bars in the window (default: 10.0)
    # @param annualization [Float]  Periods per year; 1 leaves the per-bar figure (default: 252.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rsi(real, time_period: 14.0)
    # Relative Strength Index
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rvi(real, time_period: 14.0, std_dev_period: 10.0)
    # Relative Volatility Index
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period of the Wilder smoothing applied to both legs (default: 14.0)
    # @param std_dev_period [Integer]  Time period of the standard deviation (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rvir(price_hl, time_period: 14.0, std_dev_period: 10.0)
    # Relative Volatility Index, refined high/low form
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Time period of the Wilder smoothing applied to both indices (default: 14.0)
    # @param std_dev_period [Integer]  Time period of the standard deviation (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rvol(price_v, time_period: 20.0)
    # Relative Volume
    #
    # @param price_v [Array(Array<Float>)]  Required price arrays: volume
    # @param time_period [Integer]  Time period (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method sar(price_hl, acceleration: 0.02, maximum: 0.2)
    # Parabolic SAR
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param acceleration [Float]  Acceleration Factor used up to the Maximum value (default: 0.02)
    # @param maximum [Float]  Acceleration Factor Maximum value (default: 0.2)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method sarext(price_hl, start_value: 0.0, offset_on_reverse: 0.0, acceleration_init_long: 0.02, acceleration_long: 0.02, acceleration_max_long: 0.2, acceleration_init_short: 0.02, acceleration_short: 0.02, acceleration_max_short: 0.2)
    # Parabolic SAR - Extended
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param start_value [Float]  Start value and direction. 0 for Auto, >0 for Long, <0 for Short (default: 0.0)
    # @param offset_on_reverse [Float]  Percent offset added/removed to initial stop on short/long reversal (default: 0.0)
    # @param acceleration_init_long [Float]  Acceleration Factor initial value for the Long direction (default: 0.02)
    # @param acceleration_long [Float]  Acceleration Factor for the Long direction (default: 0.02)
    # @param acceleration_max_long [Float]  Acceleration Factor maximum value for the Long direction (default: 0.2)
    # @param acceleration_init_short [Float]  Acceleration Factor initial value for the Short direction (default: 0.02)
    # @param acceleration_short [Float]  Acceleration Factor for the Short direction (default: 0.02)
    # @param acceleration_max_short [Float]  Acceleration Factor maximum value for the Short direction (default: 0.2)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method si(price_ohlc, limit_move: 3.0)
    # Wilder Swing Index
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @param limit_move [Float]  Largest one-bar price move the index is scaled against, in price units (default: 3.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method sin(real)
    # Vector Trigonometric Sin
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method sinh(real)
    # Vector Trigonometric Sinh
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method sma(real, time_period: 30.0)
    # Simple Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method smi(price_hlc, time_period: 13.0, fast_period: 2.0, slow_period: 25.0, signal_period: 9.0)
    # Stochastic Momentum Index
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Period of the high/low range (default: 13.0)
    # @param fast_period [Integer]  Period of the second smoothing, applied to the first (default: 2.0)
    # @param slow_period [Integer]  Period of the first smoothing, applied to the raw momentum (default: 25.0)
    # @param signal_period [Integer]  Smoothing for the signal line (period length) (default: 9.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :smi  Output values
    # @option result [Array<Float>] :smi_signal  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method sqrt(real)
    # Vector Square Root
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method sqzmom(price_hlc, bb_period: 20.0, nb_dev: 2.0, kc_period: 20.0, factor_wide: 2.0, factor_normal: 1.5, factor_narrow: 1.0)
    # Squeeze Momentum and Level
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param bb_period [Integer]  Period of the Bollinger Bands (default: 20.0)
    # @param nb_dev [Float]  Deviation multiplier for both Bollinger Bands (default: 2.0)
    # @param kc_period [Integer]  Period of the Keltner Channel, and of the momentum regression (default: 20.0)
    # @param factor_wide [Float]  Keltner width for the widest compression test (default: 2.0)
    # @param factor_normal [Float]  Keltner width for the classic squeeze test (default: 1.5)
    # @param factor_narrow [Float]  Keltner width for the tightest compression test (default: 1.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :momentum  Output values
    # @option result [Array<Integer>] :squeeze  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method stc(real, fast_period: 23.0, slow_period: 50.0, cycle_period: 10.0)
    # Schaff Trend Cycle
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Period of the fast EMA (default: 23.0)
    # @param slow_period [Integer]  Period of the slow EMA (default: 50.0)
    # @param cycle_period [Integer]  Window of both stochastic stages (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method stddev(real, time_period: 5.0, nb_dev: 1.0)
    # Standard Deviation
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 5.0)
    # @param nb_dev [Float]  Nb of deviations (default: 1.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method stoch(price_hlc, fast_k_period: 5.0, slow_k_period: 3.0, slow_k_ma_type: 0.0, slow_d_period: 3.0, slow_d_ma_type: 0.0)
    # Stochastic
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param fast_k_period [Integer]  Time period for building the Fast-K line (default: 5.0)
    # @param slow_k_period [Integer]  Smoothing for making the Slow-K line. Usually set to 3 (default: 3.0)
    # @param slow_k_ma_type [Integer]  Type of Moving Average for Slow-K (default: 0.0)
    # @param slow_d_period [Integer]  Smoothing for making the Slow-D line (default: 3.0)
    # @param slow_d_ma_type [Integer]  Type of Moving Average for Slow-D (default: 0.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :slow_k  Output values
    # @option result [Array<Float>] :slow_d  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method stochf(price_hlc, fast_k_period: 5.0, fast_d_period: 3.0, fast_d_ma_type: 0.0)
    # Stochastic Fast
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param fast_k_period [Integer]  Time period for building the Fast-K line (default: 5.0)
    # @param fast_d_period [Integer]  Smoothing for making the Fast-D line. Usually set to 3 (default: 3.0)
    # @param fast_d_ma_type [Integer]  Type of Moving Average for Fast-D (default: 0.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :fast_k  Output values
    # @option result [Array<Float>] :fast_d  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method stochrsi(real, time_period: 14.0, fast_k_period: 5.0, fast_d_period: 3.0, fast_d_ma_type: 0.0)
    # Stochastic Relative Strength Index
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @param fast_k_period [Integer]  Time period for building the Fast-K line (default: 5.0)
    # @param fast_d_period [Integer]  Smoothing for making the Fast-D line. Usually set to 3 (default: 3.0)
    # @param fast_d_ma_type [Integer]  Type of Moving Average for Fast-D (default: 0.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :fast_k  Output values
    # @option result [Array<Float>] :fast_d  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method sub(real0, real1)
    # Vector Arithmetic Subtraction
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method sum(real, time_period: 30.0)
    # Summation
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method supertrend(price_hlc, time_period: 10.0, multiplier: 3.0)
    # SuperTrend
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period for the Average True Range (default: 10.0)
    # @param multiplier [Float]  ATR multiplier for band width (default: 3.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :supertrend  Output values
    # @option result [Array<Integer>] :trend  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method swak_2php(real, time_period: 20.0)
    # Swiss Army Knife - Two-Pole High-Pass Filter
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Cutoff period (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method swak_bp(real, time_period: 20.0, delta: 0.1)
    # Swiss Army Knife - Band-Pass Filter
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Center period (default: 20.0)
    # @param delta [Float]  Half-bandwidth as a fraction of the center period (default: 0.1)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method swak_butter(real, time_period: 20.0)
    # Swiss Army Knife - Butterworth Filter
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Cutoff period (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method swak_gauss(real, time_period: 20.0)
    # Swiss Army Knife - Gaussian Filter
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Cutoff period (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method swak_hp(real, time_period: 20.0)
    # Swiss Army Knife - High-Pass Filter
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Cutoff period (default: 20.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method t3(real, time_period: 5.0, v_factor: 0.7)
    # Triple Exponential Moving Average (T3)
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 5.0)
    # @param v_factor [Float]  Volume Factor (default: 0.7)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method tan(real)
    # Vector Trigonometric Tan
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method tanh(real)
    # Vector Trigonometric Tanh
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method tema(real, time_period: 30.0)
    # Triple Exponential Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method trange(price_hlc)
    # True Range
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method trima(real, time_period: 30.0)
    # Triangular Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method trix(real, time_period: 30.0)
    # 1-day Rate-Of-Change (ROC) of a Triple Smooth EMA
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method tsf(real, time_period: 14.0)
    # Time Series Forecast
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method tsi(real, first_period: 25.0, second_period: 13.0)
    # True Strength Index
    #
    # @param real [Array<Float>]  Input values
    # @param first_period [Integer]  Period of the first smoothing, applied to the raw momentum (default: 25.0)
    # @param second_period [Integer]  Period of the second smoothing, applied to the first (default: 13.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method typprice(price_hlc)
    # Typical Price
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ultosc(price_hlc, time_period1: 7.0, time_period2: 14.0, time_period3: 28.0)
    # Ultimate Oscillator
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period1 [Integer]  Number of bars for 1st period. (default: 7.0)
    # @param time_period2 [Integer]  Number of bars fro 2nd period (default: 14.0)
    # @param time_period3 [Integer]  Number of bars for 3rd period (default: 28.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method var(real, time_period: 5.0, nb_dev: 1.0)
    # Variance
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 5.0)
    # @param nb_dev [Float]  Nb of deviations (default: 1.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method vhf(real, time_period: 28.0)
    # Vertical Horizontal Filter
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 28.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method vidya(real, time_period: 12.0, cmo_period: 9.0)
    # Variable Index Dynamic Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  EMA-equivalent smoothing period, alpha = 2/(n+1) (default: 12.0)
    # @param cmo_period [Integer]  Period of the unsmoothed CMO that scales alpha (default: 9.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method vortex(price_hlc, time_period: 14.0)
    # Vortex Indicator
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Number of bars in the rolling sums (default: 14.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :plus_vi  Output values
    # @option result [Array<Float>] :minus_vi  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method vwap(price_hlcv)
    # Volume Weighted Average Price
    #
    # @param price_hlcv [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close, volume
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method vwma(real, price_v, time_period: 30.0)
    # Volume Weighted Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param price_v [Array(Array<Float>)]  Required price arrays: volume
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method wad(price_hlc)
    # Williams' Accumulation/Distribution
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method wavetrend(price_hlc, channel_period: 10.0, average_period: 21.0, signal_period: 4.0)
    # WaveTrend Oscillator
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param channel_period [Integer]  Period of the price channel, used by both the average and the deviation (default: 10.0)
    # @param average_period [Integer]  Smoothing for the oscillator line (default: 21.0)
    # @param signal_period [Integer]  Simple average of the oscillator line, making the signal line (default: 4.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :wt1  Output values
    # @option result [Array<Float>] :wt2  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method wclprice(price_hlc)
    # Weighted Close Price
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method willr(price_hlc, time_period: 14.0)
    # Williams' %R
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Time period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method wma(real, time_period: 30.0)
    # Weighted Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method zigzag(price_hl, sensitivity: 5.0, min_trend_length: 1.0)
    # Zig Zag
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param sensitivity [Float]  Minimum move away from the current extreme that reverses the leg, in percent (default: 5.0)
    # @param min_trend_length [Integer]  Minimum number of bars between two pivots (default: 1.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :zig_zag  Output values
    # @option result [Array<Integer>] :trend  Output values
    # @option result [Array<Integer>] :pivot_idx  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method zlema(real, time_period: 30.0)
    # Zero-Lag Exponential Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Time period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    ### GENERATED DOCUMENTATION END ###
  end
end
