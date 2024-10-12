require 'zlib'
# You can use print statements as follows for debugging, they'll be visible when running tests.
# puts "Logs from your program will appear here!"

# Uncomment this block to pass the first stage

command = ARGV[0]
case command
when "init"
  Dir.mkdir(".git")
  Dir.mkdir(".git/objects")
  Dir.mkdir(".git/refs")
  File.write(".git/HEAD", "ref: refs/heads/main\n")
  puts "Initialized git directory"
when "cat-file"
  object_hsh = ARGV[2]
  file_path = ".git/objects/#{object_hsh[0,2]}/#{object_hsh[2,38]}"
  compressed_data = File.read(file_path)
  decompressed_data = Zlib::Inflate.inflate(compressed_data)
  headers, content = decompressed_data.split("\0")
  print "#{content}"
else
  raise RuntimeError.new("Unknown command #{command}")
end
