#!/home/x42/.rvm/rubies/ruby-1.9.2-p290/bin/ruby
require 'serialport'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  options[:device] = '/dev/ttyUSB0'
  opts.on( '-d DEVICE', '--device DEVICE', "'DEVICE to listen to. (default: #{options[:device]})" ) do |d|
    options[:device] = d
   end

  options[:mode]= 'raw'
  opts.on("-m MODE", "--mode MODE", "Possible modes are: 'raw', 'ruby' and 'munin'. (default: #{options[:mode]})") do |m|
    options[:mode] = m
  end


  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end

  opts.on("--debug", "Debug outputs (Developers only)") do |debug|
    options[:debug] = debug
    options[:verbose] = debug
  end

end.parse!

p options if options[:debug]

allowed_serial_keys = ['CPS','CPM','uSv/hr']

sp = SerialPort.new(options[:device], 9600, 8, 1, SerialPort::NONE)

# recieve part
Thread.new do
  while TRUE do
    while (serialdata = sp.gets) do

      puts serialdata if options[:verbose] || options[:mode].eql?('raw')

      row = Hash.new
      row['epoch']=Time.new.to_i
      row['time']=Time.new

      serialarray = serialdata.chomp.split(/, /)

      serialarray.each_with_index do |item, index|
        if allowed_serial_keys.include?(item) && index+2 < serialarray.length
          row[item]= serialarray[index+1]
        end
      end

      #format output fitting to output mode
      if options[:mode].eql?('ruby')
        p row
      end

      if options[:mode].eql?('munin')
        response = ""
        row.each do |key,value|
          if !key.eql?('time') && !key.eql?('epoch') && !key.eql?('uSv/hr')
            response << "#{key}.value #{value}\n"
          end
        end

        # if valid : puts and quit
        if response.gsub(/CPM.value \d+/)
          puts response
          exit
        end

      end

    end
  end
end

# send part
begin
  while TRUE do
    sp.print STDIN.gets.chomp
  end
rescue Interrupt
  sp.close
  puts#insert a newline character after ^C
end 

