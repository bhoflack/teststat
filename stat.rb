require 'rubygems'
require 'grit'

require 'rss/1.0'
require 'rss/2.0'

include Grit

@repo = Repo.new("/home/brh/Work/java/pfus")

def blobs_for_tree(tree)
  blobs = []
  tree.contents.each do |item|
    if item.instance_of? Grit::Tree
      blobs.concat(blobs_for_tree(item))
    else
      blobs << item
    end
  end

  blobs
end

def files_for_commit(commit)
  files = []
  
  @repo.commits(commit).each do |c|
    files.concat(blobs_for_tree(c.tree))    
  end

  files
end

def uniq_filenames_for_commit(commit)
  files_for_commit(commit).map { |i| i.name }.uniq
end

def modified_tests(issue)
  uniq_filenames_for_commit(issue).reject do |filename|
    (filename =~ /Test.java/) == nil
  end
end

def create_rss(url)
  content = ""
  open(url) do |s| content = s.read end
  RSS::Parser.parse(content, false)
end

def extract_keys(rss)
  keys = []
  rss.items.each do |item|
    title = item.title
    if title =~ /\[([a-zA-Z0-9-]*)\]/
      keys << $1
    end
  end

  keys
end

def tests_for_issues(url)
  rss = create_rss(url)
  keys = extract_keys(rss)
  issues_with_test = 0
  
  keys.each do |key|
    tests = modified_tests key
    puts "#{tests.size} test(s) modified for issue #{key}"
    puts tests

    issues_with_test += 1 unless tests.size == 0
  end

  percentage = Float(issues_with_test) / keys.size * 100
  puts "#{issues_with_test} issue(s) with test => that is #{percentage.round}%"
end

tests_for_issues(ARGV[0])


