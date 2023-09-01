#!/usr/bin/env ruby
require 'pathname'

puts("Usage: ruby testOptions.rb [op1] [op2] [times to run benchmarks]\n [op] is of the form --enable-neon")

$libdvbcsa_dir = Pathname.new '..'

op1 = ARGV[0].to_s  #"--enable-uint32"
op2 = ARGV[1].to_s  #"--enable-uint64"

$log = "./testOptions.log"

runBenchTimes = ARGV[2].to_i

$benchmarks = [ "benchbitslice" ] #, "benchbitsliceenc" , "benchbitslicedec"]

def runBenchMarks(option, numberOfTimes)
  puts "configuring with #{option}"
  `cd #{$libdvbcsa_dir}; \
  ./configure #{option}; \
  make`

  #run benchmarks
  $benchmarks.each do |test|
    puts(test)
    infile = $libdvbcsa_dir + "test" + "#{test}"
    outfile = "_temp/#{test}#{option}"
    numberOfTimes.times{ `sh #{infile} >> #{outfile}`}
  end
end

def compareBenchMarks(op1, op2)
  f = File.open($log, 'w') 
  f.write("#{op1} #{op2}\n")
  
  $benchmarks.each do |bench|

    f.write(bench + "\n")
    t = `diff --suppress-common-lines --side-by-side _temp/#{bench}#{op1} _temp/#{bench}#{op2}`.split("\n")
    t.select!{|s| s.match?(/[0-9]+\.[0-9]+/)}
    t.map!{|s| l = s.match(/([0-9]+\.[0-9]+) .* ([0-9]+\.[0-9]+) .*/); [l[1],l[2]]}
    count = 0
    num = t.size
    t.each{|a,b| 
      outstr = "%.1f %.1f %5s %-5s\n" % [a, b, (a.to_f-b.to_f).round(1), (a.to_f>b.to_f)?'+':'-']
      count +=1 if a.to_f >= b.to_f
      f.write(outstr) 
    }
    f.write(count.to_s + "/#{num}\n")
  end
end

`mkdir _temp`
`rm -f #{$log}`
puts ("outputs to #{$log}")
puts ("each benchmark test running #{runBenchTimes} times")
runBenchMarks(op1, runBenchTimes)
runBenchMarks(op2, runBenchTimes)

compareBenchMarks(op1, op2)

`rm -rf _temp`
