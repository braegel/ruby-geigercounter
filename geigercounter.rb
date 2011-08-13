require 'serialport'
if ARGV.size < 1
  STDERR.print <<EOF
  Usage: #{$0} serial_port
EOF
  exit(1)
end

allowed_serial_keys = ['CPS','CPM','uSv/hr']

sp = SerialPort.new(ARGV[0], 9600, 8, 1, SerialPort::NONE)

# recieve part
Thread.new do
  while TRUE do
    while (serialdata = sp.gets) do
#      puts serialdata

      row = Hash.new
      row['epoch']=Time.new.to_i
      row['time']=Time.new

      serialarray = serialdata.chomp.split(/, /)

      serialarray.each_with_index do |item, index|
        if allowed_serial_keys.include?(item) && index+2 < serialarray.length
          row[item]= serialarray[index+1]
        end
      end
      p row
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

