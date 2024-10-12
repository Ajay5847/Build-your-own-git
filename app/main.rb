require 'zlib'
require 'digest'
require 'fileutils'
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
when "hash-object"
  file_path = ARGV[2]
  write_mode = ARGV[1]
  data = File.read(file_path)
  header = "blob #{data.bytesize}\0"
  data_to_hsh = header + data
  sha1_hsh = Digest::SHA1.hexdigest(data_to_hsh)
  if write_mode == "-w"
    compressed_data = Zlib::Deflate.deflate(data_to_hsh)
    dir_path = ".git/objects/#{sha1_hsh[0,2]}"
    file_name = "#{sha1_hsh[2..-1]}"
    FileUtils.mkdir_p(dir_path)
    File.write("#{dir_path}/#{file_name}", compressed_data)
  end
  print sha1_hsh
when "ls-tree"
  tree_hsh = ARGV[2]
  file_path = ".git/object/#{tree_hsh[0..1]}/#{tree_hsh[2..-1]}"
  compressed_data = File.read(file_path)
  decompressed_data = Zlib::Inflate.inflate(compressed_data)
  print decompressed_data
  # headers, content = decompressed_data.split(" ")
else
  raise RuntimeError.new("Unknown command #{command}")
end
