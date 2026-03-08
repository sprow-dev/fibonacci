require 'time'

BUF_SZ = 32*1024*1024 # 32mb to handle slow ruby write speeds

def worker(state)
    a = 0
    b = 1

    File.open("fib.txt","wb") do |f|
        f.advise(:sequential)
        f.sync = false

        while !state[:stop]
            a,b=b,a+b

            f.write(b.to_s(16))
            f.write(",")
        end
        f.flush
    end
end

puts "Benchmarking fibonacci calculation performance"
puts "Test language: Ruby"

state = { stop:false }

t = Thread.new{worker(state)}

sleep(5)
state[:stop] = true

t.join

if File.exist?("fib.txt")
    final_size = File.size("fib.txt")
    size_mb = final_size/(1024.0*1024.0)
    puts "Test completed in 5s."
    puts "Write %.2f MB" % size_mb
    puts "That's %.2fMB/s" % (size_mb / 5)
else
    puts "Error: could not find file."
end
