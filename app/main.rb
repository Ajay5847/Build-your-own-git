require 'zlib'
require 'digest'
require 'fileutils'
# You can use print statements as follows for debugging, they'll be visible when running tests.
# puts "Logs from your program will appear here!"

# Uncomment this block to pass the first stage
# def create_tree(dir_path)
#   tree_entries = []
#   Dir.entries(dir_path).sort.each do |path|
#     next if ['.', '..', '.git'].include?(path)

#     full_path = "#{dir_path}/#{path}"
#     is_dir = Dir.exist?(full_path)

#     if is_dir
#       mode = '40000'
#       sha1_hsh = create_tree(full_path)
#     else
#       mode = '100644'  
#       sha1_hsh = create_blob(full_path)
#     end

#     tree_entries << "#{mode} #{path}\0#{sha1_hsh[:bin_digest]}"
#   end

#   full_entry_data = tree_entries.join('')
#   header = "tree #{full_entry_data.bytesize}\0"
#   data_to_hsh = header + full_entry_data
#   tree_sha1 = Digest::SHA1.hexdigest(data_to_hsh)
#   store_object(tree_sha1, full_entry_data)
#   tree_sha1
# end

# def create_blob(file_path)
#   data = File.read(file_path)
#   header = "blob #{data.bytesize}\0"
#   data_to_hsh = header + data
#   data_hex_hsh = Digest::SHA1.hexdigest(data_to_hsh)
#   data_bin_hsh = Digest::SHA1.digest(data_to_hsh)
#   store_object(data_hex_hsh, data)
#   {
#     hex_digest: data_hex_hsh,
#     bin_digest: data_bin_hsh
#   }
# end

def store_object(sha_hsh, data)
  compressed_data = Zlib::Deflate.deflate(data)
  dir_path = ".git/objects/#{sha_hsh[0..1]}"
  file_name = "#{sha_hsh[2..-1]}"

  FileUtils.mkdir_p(dir_path)
  File.write("#{dir_path}/#{file_name}", compressed_data)
end

def process_dir(dirname)
  tree_entries = []
  Dir.entries(dirname).sort.each do |entry|
    path = "#{dirname}/#{entry}"
    is_dir = Dir.exist?(path)
    next if ['.', '..', '.git'].include?(entry)
    entry_mode = is_dir ? '40000' : '100644'
    entry_content = if is_dir
                      process_dir(path)
                    else
                      process_content(File.read(path), 'blob')
                    end
    tree_entries << "#{entry_mode} #{entry}\0#{entry_content[:binary_digest]}"
  end
  process_content(tree_entries.join(''), 'tree')
end

def process_content(content, header_type)
  entry_content = "#{header_type} #{content.bytes.length}\0#{content}"
  hex_digest = Digest::SHA1.hexdigest(entry_content)
  binary_digest = Digest::SHA1.digest(entry_content)
  git_object_dir = File.join(Dir.pwd, '.git', 'objects', hex_digest[0..1])
  Dir.mkdir(git_object_dir) unless Dir.exist?(git_object_dir)
  git_object_path = File.join(git_object_dir, hex_digest[2..])
  File.write(git_object_path, Zlib::Deflate.deflate(entry_content))
  {
    hex_digest: hex_digest,
    binary_digest: binary_digest
  }
end

def create_commit(tree_sha, parent_flag, parent_sha, message_flag, message)
  author_name = "Ajay5847"
  author_email = "ajay@ca.co"
  committer_name = "AjayBunty"
  committer_email = "ajaybunty@ca.co"
  author_time = committer_time = Time.now

  author_info = "#{author_name} #{author_email} #{author_time}"
  committer_info = "#{committer_name} #{committer_email} #{committer_time}"
  tree_info = "tree #{tree_sha}"
  parent_info = "parent #{parent_sha}"

  content = [tree_info, parent_info, author_info, committer_info, ' ', message].join("\n") + "\n"
  header = "commit #{content.bytesize}\0"
  data_to_hsh = header + content
  commit_sha = Digest::SHA1.hexdigest(data_to_hsh)
  store_object(commit_sha, data_to_hsh)
  commit_sha
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
    
    # Ensure internal_data contains a valid file name, ignoring binary data
    if internal_data[-1] =~ /\A[\x20-\x7E]+\z/
      puts internal_data[-1]
    end
  end
when "write-tree"
  puts process_dir(Dir.pwd)[:hex_digest]
when "commit-tree"
  tree_sha = ARGV[1]
  parent_flag = ARGV[2]
  parent_sha = ARGV[3]
  message_flag = ARGV[4]
  message = ARGV[5]
  puts create_commit(tree_sha, parent_flag, parent_sha, message_flag, message)
when "clone"
  url = ARGV[1]
  directory = ARGV[2]
  system("git clone #{url} #{directory}")
else
  raise RuntimeError.new("Unknown command #{command}")
end