#
# Benchmark Collection
#
# Attributes:
# - name
# - path
# - analyses (list)
#   - analysis_entry ... function to be analyzed
#   - trace_entry ... entry for trace analysis
# - recursive   ... benchmark has recursion
# - irreducible ... benchmark has irreducible loops
# - disable_sweet    ... SWEET fails for this benchmark
# - expensive ... long running benchmark, only include for full tests

# MRTC
#
def mrtc_benchmarks
  # SWEET fails with no final states for qsort-exam,-O1 and select,-O0
  disable_sweet = %w{qsort-exam select}
  # long running in decreasing order
  long_running = %w{lms ludcmp minver fft1 qurt nischneu}
  # all benchmarks
  benchmarks = %w{adpcm bs bsort100 cnt compress cover crc duff
     edn expint fac fdct fft1 fibcall fir insertsort janne_complex jfdctint lcdnum lms loop3
     ludcmp matmult minmax minver ndes ns nsichneu qsort-exam qurt recursion select sqrt statemate ud}
  shortname = Hash.new { |ht,k| k }.merge('janne_complex' => 'janne', 'qsort-exam' => 'qsort')
  analyses = [{ 'name' => 'main', 'analysis_entry' => 'main', 'trace_entry' => 'main' }]
  benchmarks.map do |name|
    { 'analyses' => analyses,
      'name' => "mrtc_#{shortname[name]}",
      'suite' => 'mrtc',
      'path' => File.join("Malardalen","src",name),
      'recursive' => %w{fac recursion}.include?(name), # benchmarks with (direct) recursion
      'irreducible' => %w{duff}.include?(name),   # duff has irreducible loop for -O0
      'expensive' => long_running.include?(name),
      'disable-sweet' => disable_sweet.include?(name) }
  end
end

def papabench
  benchmarks = %w{fly_by_wire autopilot}
  shortname = { 'fly_by_wire' => 'fbw', 'autopilot' => 'autopilot' }
  targets = {
    'fly_by_wire' => %w{check_failsafe_task check_mega128_values_task send_data_to_autopilot_task servo_transmit test_ppm_task},
    'autopilot' =>  %w{altitude_control_task climb_control_task link_fbw_send navigation_task radio_control_task receive_gps_data_task reporting_task stabilisation_task} # main
  }
  benchmarks = benchmarks.map { |bench|
    { 'analyses' => targets[bench].map { |entry|
        { 'name' => entry,
          'analysis_entry' => entry,
          'trace_entry' => 'main'
        }
      },
      'name' => "papa_#{shortname[bench]}",
      'path' => File.join("PapaBench-0.4","sw","airborne",bench,bench),
      'expensive' => bench == 'autopilot'
    }
  }
end

def wcet_tests
  benchmarks = %w{triangle1 triangle2 triangle3 lift_cov}
  targets = Hash.new(['run'])
  targets['lift_cov'] = ['ctrl_init', 'controller']
  benchmarks.map { |bench|
    { 'analyses' => targets[bench].map { |entry|
        { 'name' => entry,
          'analysis_entry' => entry,
          'trace_entry' => 'main'
        }
      },
      'name' => "tests_#{bench}",
      'path' => File.join("tests","C",bench),
      'expensive' => false
    }
  }
end

def all_benchmarks
  mrtc_benchmarks + wcet_tests + papabench
end

# Standard Build settings
def standard_buildsettings
  [ {'name' => 'O0', 'cflags' => '-O0', 'ldflags' => '' }, # todo: remove empty blocks
    {'name' => 'O1', 'cflags' => '-O1', 'ldflags' => '' },
    {'name' => 'O1f', 'cflags' => '-O1 -Xopt -disable-inlining', 'ldflags' => '' },
    {'name' => 'O2', 'cflags' => '-O2', 'ldflags' => '' },
    {'name' => 'Os', 'cflags' => '-Os', 'ldflags' => '-Os'} ]
end

# Standard Configurations
def standard_configurations
  [ {'name' => 'blockglobal', 'recorders' => 'g:bcl,f:b', 'flow-fact-selection' => 'all' },
    {'name' => 'blocklocal',  'recorders' => 'g:cil,f:b', 'flow-fact-selection' => 'local' },
    {'name' => 'minimal', 'recorders' => 'g:cil', 'flow-fact-selection' => 'minimal' },
    {'name' => 'notrace', 'flow-fact-selection' => 'all'}]
end
