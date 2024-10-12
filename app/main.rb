require 'zlib'
require 'digest'
require 'fileutils'
# You can use print statements as follows for debugging, they'll be visible when running tests.
# puts "Logs from your program will appear here!"

# Uncomment this block to pass the first stage
def create_tree(dir_path)
  entries = []
  Dir.entries(dir_path).sort.each do |path|
    next if ['.', '..', '.git'].include?(path)

    full_path = File.join(dir_path, path)
    is_dir = Dir.exist?(full_path)

    if is_dir
      mode = 40000
      sha1_hsh = create_tree(full_path)
    else
      mode = 100644  
      sha1_hsh = create_blob(full_path)
    end

    entries << "#{mode} #{path}\0#{sha1_hsh}"
  end

  full_entry_data = entries.join('')
  header = "tree #{full_entry_data.bytesize}\0"
  data_to_hsh = header + full_entry_data
  tree_sha1 = Digest::SHA1.hexdigest(data_to_hsh)
  store_object(tree_sha1, full_entry_data)
  tree_sha1
end


def create_blob(file_path)
  data = File.read(file_path)
  header = "blob #{data.bytesize}\0"
  data_to_hsh = header + data
  data_hex_hsh = Digest::SHA1.hexdigest(data_to_hsh)
  data_bin_hsh = Digest::SHA1.digest(data_to_hsh)
  store_object(data_hex_hsh, data)
  data_bin_hsh
end

def store_object(sha_hsh, data)
  compressed_data = Zlib::Deflate.deflate(data)
  dir_path = ".git/objects/#{sha_hsh[0..1]}"
  file_name = "#{sha_hsh[2..-1]}"

  FileUtils.mkdir_p(dir_path)
  File.write("#{dir_path}/#{file_name}", compressed_data)
end

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
  file_path = ".git/objects/#{tree_hsh[0..1]}/#{tree_hsh[2..-1]}"
  compressed_data = File.read(file_path)
  decompressed_data = Zlib::Inflate.inflate(compressed_data)
  splitted_data = decompressed_data.split("\0")
  splitted_data[1..-2].each do |data|
    internal_data = data.split(' ')
    puts internal_data[-1]
  end
when "write-tree"
  tree_sha_hsh = create_tree(Dir.pwd)
  puts tree_sha_hsh
else
  raise RuntimeError.new("Unknown command #{command}")
end