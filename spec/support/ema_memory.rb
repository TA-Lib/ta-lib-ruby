# frozen_string_literal: true

require "ta_lib_ffi"

# Run in a fresh Linux process so other examples and their garbage do not
# affect the measured resident set. Print the growth after the warm-up batch.
def resident_kib
  Integer(File.read("/proc/self/status")[/^VmRSS:\s+(\d+)/, 1])
end

prices = (1..512).to_a.freeze
batch = lambda do
  1024.times { TALibFFI.ema(prices, time_period: 14) }
  GC.start
end
batch.call
baseline = resident_kib
4.times { batch.call }
puts resident_kib - baseline
