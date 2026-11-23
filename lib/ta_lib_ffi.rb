# frozen_string_literal: true

require "fiddle"
require "fiddle/import"
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

  lib_path = case RUBY_PLATFORM
             when /darwin/
               brew_prefix = `brew --prefix`.chomp
               "#{brew_prefix}/lib/libta-lib.dylib"
             when /linux/
               "libta-lib.so"
             when /cygwin|mswin|mingw|bccwin|wince|emx/
               "C:/Program Files/TA-Lib/bin/ta-lib.dll"
             else
               raise "Unsupported platform"
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

  # {0,"SMA"},
  # {1,"EMA"},
  # {2,"WMA"},
  # {3,"DEMA" },
  # {4,"TEMA" },
  # {5,"TRIMA"},
  # {6,"KAMA" },
  # {7,"MAMA" },
  # {8,"T3"}

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

  TA_FuncInfo = struct [
    "const char *name",
    "const char *group",
    "const char *hint",
    "const char *camelCaseName",
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
      TA_OUT_LOWER_LIMIT: 0x00001000
    }
  }.freeze

  extern "int TA_Initialize()"
  extern "int TA_Shutdown()"
  extern "int TA_GroupTableAlloc(TA_StringTable**)"
  extern "int TA_GroupTableFree(TA_StringTable*)"
  extern "TA_RetCode TA_FuncTableAlloc(const char *group, TA_StringTable **table)"
  extern "TA_RetCode TA_FuncTableFree(TA_StringTable *table)"
  extern "TA_FuncHandle TA_GetFuncHandle(const char *name, const TA_FuncHandle **handle)"
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
    flags_set = []
    TA_FLAGS[type].each do |k, v|
      flags_set << k if (value & v) != 0
    end
    flags_set
  end

  # Returns a list of all available function groups in TA-Lib
  #
  # @return [Array<String>] Array of group names
  def group_table
    string_table_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    ret_code = TA_GroupTableAlloc(string_table_ptr.ref)
    check_ta_return_code(ret_code)

    string_table = TA_StringTable.new(string_table_ptr)
    group_names = Fiddle::Pointer.new(string_table["string"])[0, Fiddle::SIZEOF_VOIDP * string_table["size"]].unpack("Q*").collect { |ptr| Fiddle::Pointer.new(ptr).to_s }
    TA_GroupTableFree(string_table_ptr)

    group_names
  end

  # Returns a list of all functions in a specific group
  #
  # @param group [String] The name of the group to get functions for
  # @return [Array<String>] Array of function names in the group
  def function_table(group)
    string_table_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    ret_code = TA_FuncTableAlloc(group, string_table_ptr.ref)
    check_ta_return_code(ret_code)

    string_table = TA_StringTable.new(string_table_ptr)
    func_names = Fiddle::Pointer.new(string_table["string"])[0, Fiddle::SIZEOF_VOIDP * string_table["size"]].unpack("Q*").collect { |ptr| Fiddle::Pointer.new(ptr).to_s }

    TA_FuncTableFree(string_table)

    func_names
  end

  # Gets detailed information about a specific TA-Lib function
  #
  # @param name [String] The name of the function to get information for
  # @return [Fiddle::CStructEntity] Struct containing function information
  def function_info(name)
    handle_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    ret_code = TA_GetFuncHandle(name, handle_ptr.ref)
    check_ta_return_code(ret_code)

    info_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    ret_code = TA_GetFuncInfo(handle_ptr, info_ptr.ref)
    check_ta_return_code(ret_code)

    TA_FuncInfo.new(info_ptr)
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
    puts "Camel Case Name: #{func_info["camelCaseName"]}"
    puts "Flags: #{func_info["flags"]}"
    puts "Number of Inputs: #{func_info["nbInput"]}"
    puts "Number of Optional Inputs: #{func_info["nbOptInput"]}"
    puts "Number of Outputs: #{func_info["nbOutput"]}"
    puts "Function Handle: #{func_info["handle"].to_i}"

    puts "\nInput Parameter Info:"
    func_info["nbInput"].times do |i|
      param_info_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
      ret_code = TA_GetInputParameterInfo(func_info["handle"], i, param_info_ptr.ref)
      check_ta_return_code(ret_code)
      param_info = TA_InputParameterInfo.new(param_info_ptr)
      puts "  Parameter #{i + 1}:"
      puts "    Name: #{param_info["paramName"]}"
      puts "    Type: #{param_info["type"]}"
      puts "    Flags: #{extract_flags(param_info["flags"], :TA_InputFlags)}"
    end

    puts "\nOptional Input Parameter Info:"
    func_info["nbOptInput"].times do |i|
      param_info_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
      ret_code = TA_GetOptInputParameterInfo(func_info["handle"], i, param_info_ptr.ref)
      check_ta_return_code(ret_code)
      param_info = TA_OptInputParameterInfo.new(param_info_ptr)
      puts "  Parameter #{i + 1}:"
      puts "    Name: #{param_info["paramName"]}"
      puts "    Type: #{param_info["type"]}"
      puts "    Flags: #{extract_flags(param_info["flags"], :TA_OptInputFlags)}"
      puts "    Display Name: #{param_info["displayName"]}"
      puts "    Default Value: #{param_info["defaultValue"]}"
      puts "    Hint: #{param_info["hint"]}"
    end

    puts "\nOutput Parameter Info:"
    func_info["nbOutput"].times do |i|
      param_info_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
      ret_code = TA_GetOutputParameterInfo(func_info["handle"], i, param_info_ptr.ref)
      check_ta_return_code(ret_code)
      param_info = TA_OutputParameterInfo.new(param_info_ptr)
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
  def call_func(func_name, args) # rubocop:disable Metrics/MethodLength
    options = args.last.is_a?(Hash) ? args.pop : {}
    input_arrays = args

    validate_inputs!(input_arrays)

    handle_ptr = get_function_handle(func_name)
    params_ptr = create_parameter_holder(handle_ptr)

    begin
      setup_input_parameters(params_ptr, input_arrays, func_name)
      setup_optional_parameters(params_ptr, options, func_name)
      _lookback = calculate_lookback(params_ptr)
      calculate_results(params_ptr, input_arrays, func_name)
    ensure
      TA_ParamHolderFree(params_ptr)
    end
  end

  # Calculates the lookback period for a function with given parameters
  #
  # @param params_ptr [Fiddle::Pointer] Pointer to parameter holder
  # @return [Integer] The lookback period
  def calculate_lookback(params_ptr)
    lookback_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    ret_code = TA_GetLookback(params_ptr, lookback_ptr)
    check_ta_return_code(ret_code)
    lookback_ptr[0, Fiddle::SIZEOF_INT].unpack1("l")
  end

  # Validates input arrays for TA-Lib functions
  #
  # @param arrays [Array<Array>] Arrays to validate
  # @raise [TALibError] If any array is invalid
  def validate_inputs!(arrays) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    raise TALibError, "Input arrays cannot be empty" if arrays.empty?

    arrays.each do |arr|
      raise TALibError, "Input must be arrays" unless arr.is_a?(Array)
    end

    sizes = arrays.map(&:length)
    raise TALibError, "Input arrays cannot be empty" if sizes.any?(&:zero?)

    arrays.each do |arr|
      raise TALibError, "Input arrays must contain only numbers" unless arr.flatten.all? { |x| x.is_a?(Numeric) }
    end
  end

  # Gets a function handle for a given function name
  #
  # @param func_name [String] The name of the function
  # @return [Fiddle::Pointer] Pointer to function handle
  def get_function_handle(func_name)
    handle_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    ret_code = TA_GetFuncHandle(func_name, handle_ptr.ref)
    check_ta_return_code(ret_code)
    handle_ptr
  end

  # Creates a parameter holder for a function
  #
  # @param handle_ptr [Fiddle::Pointer] Function handle pointer
  # @return [Fiddle::Pointer] Pointer to parameter holder
  def create_parameter_holder(handle_ptr)
    params_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    ret_code = TA_ParamHolderAlloc(handle_ptr, params_ptr.ref)
    check_ta_return_code(ret_code)
    params_ptr
  end

  # Sets up input parameters for a function call
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param input_arrays [Array<Array>] Input data arrays
  # @param func_name [String] Function name
  def setup_input_parameters(params_ptr, input_arrays, func_name)
    func_info = function_info_map[func_name]
    input_arrays.each_with_index do |array, index|
      input_info = func_info[:inputs][index]
      ret_code = set_input_parameter(params_ptr, index, array, input_info)
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
  def set_input_parameter(params_ptr, index, array, input_info)
    case input_info["type"]
    when TA_PARAM_TYPE[:TA_Input_Real]
      input_ptr = prepare_double_array(array)
      TA_SetInputParamRealPtr(params_ptr, index, input_ptr)
    when TA_PARAM_TYPE[:TA_Input_Integer]
      input_ptr = prepare_integer_array(array)
      TA_SetInputParamIntegerPtr(params_ptr, index, input_ptr)
    when TA_PARAM_TYPE[:TA_Input_Price]
      setup_price_inputs(params_ptr, index, array, input_info["flags"])
    end
  end

  # Prepares a double array for TA-Lib input
  #
  # @param array [Array<Numeric>] Array of numbers to prepare
  # @return [Fiddle::Pointer] Pointer to prepared array
  def prepare_double_array(array)
    array_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DOUBLE * array.length)
    array.each_with_index do |value, i|
      array_ptr[i * Fiddle::SIZEOF_DOUBLE, Fiddle::SIZEOF_DOUBLE] = [value.to_f].pack("d")
    end
    array_ptr
  end

  # Prepares an integer array for TA-Lib input
  #
  # @param array [Array<Numeric>] Array of numbers to prepare
  # @return [Fiddle::Pointer] Pointer to prepared array
  def prepare_integer_array(array)
    array_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT * array.length)
    array.each_with_index do |value, i|
      array_ptr[i * Fiddle::SIZEOF_INT, Fiddle::SIZEOF_INT] = [value.to_i].pack("l")
    end
    array_ptr
  end

  # Sets up optional parameters for a function call
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param options [Hash] Optional parameters
  # @param func_name [String] Function name
  def setup_optional_parameters(params_ptr, options, func_name)
    func_info = function_info_map[func_name]
    func_info[:opt_inputs]&.each_with_index do |opt_input, index|
      param_name = normalize_parameter_name(opt_input["paramName"].to_s)
      set_optional_parameter(params_ptr, index, options[param_name.to_sym], opt_input["type"]) if options.key?(param_name.to_sym)
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
  def calculate_results(params_ptr, input_arrays, func_name) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    func_info = function_info_map[func_name]
    input_size = if func_info[:inputs].first["type"] == TA_PARAM_TYPE[:TA_Input_Price]
                   input_arrays[0][0].length
                 else
                   input_arrays[0].length
                 end

    out_begin = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    out_size = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    output_arrays = setup_output_buffers(params_ptr, input_size, func_name)

    begin
      ret_code = TA_CallFunc(params_ptr, 0, input_size - 1, out_begin, out_size)
      check_ta_return_code(ret_code)

      actual_size = out_size[0, Fiddle::SIZEOF_INT].unpack1("l")
      format_output_results(output_arrays, actual_size, func_name)
    ensure
      out_begin.free
      out_size.free
      output_arrays.each(&:free)
    end
  end

  # Sets up output buffers for function results
  #
  # @param params_ptr [Fiddle::Pointer] Parameter holder pointer
  # @param size [Integer] Size of output buffer
  # @param func_name [String] Function name
  # @return [Array<Fiddle::Pointer>] Array of output buffer pointers
  def setup_output_buffers(params_ptr, size, func_name) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    func_info = function_info_map[func_name]
    output_ptrs = []

    func_info[:outputs].each_with_index do |output, index|
      ptr = case output["type"]
            when TA_PARAM_TYPE[:TA_Output_Real]
              Fiddle::Pointer.malloc(Fiddle::SIZEOF_DOUBLE * size)
            when TA_PARAM_TYPE[:TA_Output_Integer]
              Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT * size)
            end

      output_ptrs << ptr

      ret_code =  case output["type"]
                  when TA_PARAM_TYPE[:TA_Output_Real]
                    TA_SetOutputParamRealPtr(params_ptr, index, ptr)
                  when TA_PARAM_TYPE[:TA_Output_Integer]
                    TA_SetOutputParamIntegerPtr(params_ptr, index, ptr)
                  end

      check_ta_return_code(ret_code)
    end

    output_ptrs
  end

  # Formats output results from TA-Lib function
  #
  # @param output_ptrs [Array<Fiddle::Pointer>] Array of output buffer pointers
  # @param size [Integer] Size of output data
  # @param func_name [String] Function name
  # @return [Array, Hash] Formatted results
  def format_output_results(output_ptrs, size, func_name) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    func_info = function_info_map[func_name]
    results = output_ptrs.zip(func_info[:outputs]).map do |ptr, output|
      case output["type"]
      when TA_PARAM_TYPE[:TA_Output_Real]
        ptr[0, Fiddle::SIZEOF_DOUBLE * size].unpack("d#{size}")
      when TA_PARAM_TYPE[:TA_Output_Integer]
        ptr[0, Fiddle::SIZEOF_INT * size].unpack("l#{size}")
      end
    end

    return results.first if results.length == 1

    output_names = func_info[:outputs].map do |output|
      normalize_parameter_name(output["paramName"].to_s).to_sym
    end
    output_names.zip(results).to_h
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
      info_map[func_info["name"].to_s] = {
        info: func_info,
        inputs: collect_input_info(func_info),
        outputs: collect_output_info(func_info),
        opt_inputs: collect_opt_input_info(func_info)
      }
    end
    info_map
  end

  # Collects input parameter information for a function
  #
  # @param func_info [Fiddle::CStructEntity] Function information
  # @return [Array<Fiddle::CStructEntity>] Array of input parameter information
  def collect_input_info(func_info)
    func_info["nbInput"].times.map do |i|
      param_info_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
      TA_GetInputParameterInfo(func_info["handle"], i, param_info_ptr.ref)
      TA_InputParameterInfo.new(param_info_ptr)
    end
  end

  # Collects optional input parameter information for a function
  #
  # @param func_info [Fiddle::CStructEntity] Function information
  # @return [Array<Fiddle::CStructEntity>] Array of optional input parameter information
  def collect_opt_input_info(func_info)
    func_info["nbOptInput"].times.map do |i|
      param_info_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
      TA_GetOptInputParameterInfo(func_info["handle"], i, param_info_ptr.ref)
      TA_OptInputParameterInfo.new(param_info_ptr)
    end
  end

  # Collects output parameter information for a function
  #
  # @param func_info [Fiddle::CStructEntity] Function information
  # @return [Array<Fiddle::CStructEntity>] Array of output parameter information
  def collect_output_info(func_info)
    func_info["nbOutput"].times.map do |i|
      param_info_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
      TA_GetOutputParameterInfo(func_info["handle"], i, param_info_ptr.ref)
      TA_OutputParameterInfo.new(param_info_ptr)
    end
  end

  # Generates Ruby methods for all TA-Lib functions
  #
  # This method iterates through all available TA-Lib functions and creates
  # corresponding Ruby methods with proper documentation.
  def generate_ta_functions
    each_function do |func_info|
      define_ta_function(func_info["name"].to_s.downcase, func_info["name"].to_s)
    end
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
  def setup_price_inputs(params_ptr, index, price_data, flags)
    required_flags = extract_flags(flags, :TA_InputFlags)
    data_pointers = Array.new(6) { Fiddle::Pointer.malloc(0) }
    required_flags.each_with_index do |flag, i|
      flag_index = TA_FLAGS[:TA_InputFlags].keys.index(flag)
      data_pointers[flag_index] = prepare_double_array(price_data[i]) if required_flags.include?(flag)
    end

    TA_SetInputParamPricePtr(params_ptr, index, *data_pointers)
  end

  initialize_ta_lib
  generate_ta_functions

  # Placeholder for generated TA-Lib function documentation.
  # Generated using YARD.
  # Run: rake yard
  class << self
    ### GENERATED DOCUMENTATION START ###
    # @!method accbands(price_hlc, time_period: 20.0)
    # Acceleration Bands
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Number of period (default: 20.0)
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
    # @param fast_period [Integer]  Number of period for the fast MA (default: 3.0)
    # @param slow_period [Integer]  Number of period for the slow MA (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method adx(price_hlc, time_period: 14.0)
    # Average Directional Movement Index
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method adxr(price_hlc, time_period: 14.0)
    # Average Directional Movement Index Rating
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method apo(real, fast_period: 12.0, slow_period: 26.0, ma_type: 0.0)
    # Absolute Price Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Number of period for the fast MA (default: 12.0)
    # @param slow_period [Integer]  Number of period for the slow MA (default: 26.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method aroon(price_hl, time_period: 14.0)
    # Aroon
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :aroon_down  Output values
    # @option result [Array<Float>] :aroon_up  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method aroonosc(price_hl, time_period: 14.0)
    # Aroon Oscillator
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Number of period (default: 14.0)
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
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method avgprice(price_ohlc)
    # Average Price
    #
    # @param price_ohlc [Array(Array<Float>, Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: open, high, low, close
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method avgdev(real, time_period: 14.0)
    # Average Deviation
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method bbands(real, time_period: 5.0, nb_dev_up: 2.0, nb_dev_dn: 2.0, ma_type: 0.0)
    # Bollinger Bands
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 5.0)
    # @param nb_dev_up [Float]  Deviation multiplier for upper band (default: 2.0)
    # @param nb_dev_dn [Float]  Deviation multiplier for lower band (default: 2.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :upper_band  Output values
    # @option result [Array<Float>] :middle_band  Output values
    # @option result [Array<Float>] :lower_band  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method beta(real0, real1, time_period: 5.0)
    # Beta
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 5.0)
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
    # @param time_period [Integer]  Number of period (default: 14.0)
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

    # @!method cmo(real, time_period: 14.0)
    # Chande Momentum Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method correl(real0, real1, time_period: 30.0)
    # Pearson's Correlation Coefficient (r)
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
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

    # @!method dema(real, time_period: 30.0)
    # Double Exponential Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method div(real0, real1)
    # Vector Arithmetic Div
    #
    # @param real0 [Array<Float>]  Input values
    # @param real1 [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method dx(price_hlc, time_period: 14.0)
    # Directional Movement Index
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ema(real, time_period: 30.0)
    # Exponential Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method exp(real)
    # Vector Arithmetic Exp
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method floor(real)
    # Vector Floor
    #
    # @param real [Array<Float>]  Input values
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

    # @!method imi(price_oc, time_period: 14.0)
    # Intraday Momentum Index
    #
    # @param price_oc [Array(Array<Float>, Array<Float>)]  Required price arrays: open, close
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method kama(real, time_period: 30.0)
    # Kaufman Adaptive Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method linearreg(real, time_period: 14.0)
    # Linear Regression
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method linearreg_angle(real, time_period: 14.0)
    # Linear Regression Angle
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method linearreg_intercept(real, time_period: 14.0)
    # Linear Regression Intercept
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method linearreg_slope(real, time_period: 14.0)
    # Linear Regression Slope
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
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
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method macd(real, fast_period: 12.0, slow_period: 26.0, signal_period: 9.0)
    # Moving Average Convergence/Divergence
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Number of period for the fast MA (default: 12.0)
    # @param slow_period [Integer]  Number of period for the slow MA (default: 26.0)
    # @param signal_period [Integer]  Smoothing for the signal line (nb of period) (default: 9.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :macd  Output values
    # @option result [Array<Float>] :macd_signal  Output values
    # @option result [Array<Float>] :macd_hist  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method macdext(real, fast_period: 12.0, fast_ma_type: 0.0, slow_period: 26.0, slow_ma_type: 0.0, signal_period: 9.0, signal_ma_type: 0.0)
    # MACD with controllable MA type
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Number of period for the fast MA (default: 12.0)
    # @param fast_ma_type [Integer]  Type of Moving Average for fast MA (default: 0.0)
    # @param slow_period [Integer]  Number of period for the slow MA (default: 26.0)
    # @param slow_ma_type [Integer]  Type of Moving Average for slow MA (default: 0.0)
    # @param signal_period [Integer]  Smoothing for the signal line (nb of period) (default: 9.0)
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
    # @param signal_period [Integer]  Smoothing for the signal line (nb of period) (default: 9.0)
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
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method maxindex(real, time_period: 30.0)
    # Index of highest value over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Integer>]
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
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method midpoint(real, time_period: 14.0)
    # MidPoint over period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method midprice(price_hl, time_period: 14.0)
    # Midpoint Price over period
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method min(real, time_period: 30.0)
    # Lowest value over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method minindex(real, time_period: 30.0)
    # Index of lowest value over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Integer>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method minmax(real, time_period: 30.0)
    # Lowest and highest values over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Float>] :min  Output values
    # @option result [Array<Float>] :max  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method minmaxindex(real, time_period: 30.0)
    # Indexes of lowest and highest values over a specified period
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Hash]  Hash containing the following arrays:
    # @option result [Array<Integer>] :min_idx  Output values
    # @option result [Array<Integer>] :max_idx  Output values
    # @raise [TALibError]  If there is an error in function execution

    # @!method minus_di(price_hlc, time_period: 14.0)
    # Minus Directional Indicator
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method minus_dm(price_hl, time_period: 14.0)
    # Minus Directional Movement
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method mom(real, time_period: 10.0)
    # Momentum
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 10.0)
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
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method obv(real, price_v)
    # On Balance Volume
    #
    # @param real [Array<Float>]  Input values
    # @param price_v [Array(Array<Float>)]  Required price arrays: volume
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method plus_di(price_hlc, time_period: 14.0)
    # Plus Directional Indicator
    #
    # @param price_hlc [Array(Array<Float>, Array<Float>, Array<Float>)]  Required price arrays: high, low, close
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method plus_dm(price_hl, time_period: 14.0)
    # Plus Directional Movement
    #
    # @param price_hl [Array(Array<Float>, Array<Float>)]  Required price arrays: high, low
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method ppo(real, fast_period: 12.0, slow_period: 26.0, ma_type: 0.0)
    # Percentage Price Oscillator
    #
    # @param real [Array<Float>]  Input values
    # @param fast_period [Integer]  Number of period for the fast MA (default: 12.0)
    # @param slow_period [Integer]  Number of period for the slow MA (default: 26.0)
    # @param ma_type [Integer]  Type of Moving Average (default: 0.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method roc(real, time_period: 10.0)
    # Rate of change : ((price/prevPrice)-1)*100
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rocp(real, time_period: 10.0)
    # Rate of change Percentage: (price-prevPrice)/prevPrice
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rocr(real, time_period: 10.0)
    # Rate of change ratio: (price/prevPrice)
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rocr100(real, time_period: 10.0)
    # Rate of change ratio 100 scale: (price/prevPrice)*100
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 10.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method rsi(real, time_period: 14.0)
    # Relative Strength Index
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
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
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method sqrt(real)
    # Vector Square Root
    #
    # @param real [Array<Float>]  Input values
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method stddev(real, time_period: 5.0, nb_dev: 1.0)
    # Standard Deviation
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 5.0)
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
    # @param time_period [Integer]  Number of period (default: 14.0)
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
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method t3(real, time_period: 5.0, v_factor: 0.7)
    # Triple Exponential Moving Average (T3)
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 5.0)
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
    # @param time_period [Integer]  Number of period (default: 30.0)
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
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method trix(real, time_period: 30.0)
    # 1-day Rate-Of-Change (ROC) of a Triple Smooth EMA
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method tsf(real, time_period: 14.0)
    # Time Series Forecast
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 14.0)
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
    # @param time_period [Integer]  Number of period (default: 5.0)
    # @param nb_dev [Float]  Nb of deviations (default: 1.0)
    # @return [Array<Float>]
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
    # @param time_period [Integer]  Number of period (default: 14.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    # @!method wma(real, time_period: 30.0)
    # Weighted Moving Average
    #
    # @param real [Array<Float>]  Input values
    # @param time_period [Integer]  Number of period (default: 30.0)
    # @return [Array<Float>]
    # @raise [TALibError]  If there is an error in function execution

    ### GENERATED DOCUMENTATION END ###
  end
end
