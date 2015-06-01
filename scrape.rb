require 'nokogiri'
require 'httparty'
require 'concurrent'
require 'optparse'

class HWZRequest

  def initialize
    @host = "http://forums.hardwarezone.com.sg"
  end

  def get_thread_paths(path)
    doc = Nokogiri::HTML(HTTParty.get(@host + '/' + path))
    thread_list_xpath = '//*[contains(@id, "thread_title_")]'
    doc.xpath(thread_list_xpath).map do |element|
      element.attributes['href'].value
    end
  end

  def get_comments(thread, page = 1, max_pages = nil, comments = [])
    url = @host + '/' + thread

    if page > 1
      splitted = url.split(".")
      splitted.pop
      splitted[-1] += "-#{page}"
      url = splitted.push("html").join(".")
    end

    begin
      doc = Nokogiri::HTML(HTTParty.get(url))
    rescue SocketError => e
      puts "Hit with SocketError #{e}, skipping.."
      comments
    end

    max_pages = max_pages_count(doc) if max_pages.nil?
    puts "SUCCESS: Thread: #{thread} - pulled page #{page}/#{max_pages}"

    comments_xpath = '//*[contains(@id, "post_message_")]'
    c = doc.xpath(comments_xpath).map do |element|
      comment = element.children.first.content.gsub(/\r|\t|\n/, " ").gsub(/\s+/, " ").strip

      # Remove '$username wrote: { ... }'
      splitted = comment.split(":")
      splitted.count > 1 ? splitted[1..-1].join(":") : splitted.first
    end

    comments.push(*c)
    page == max_pages ? comments.compact.map(&:strip).uniq : get_comments(thread, page + 1, max_pages, comments)
  end

  private

  def max_pages_count(doc)
    max_pages_xpath = '//div[@class="pagination"]'
    result = doc.xpath(max_pages_xpath).first
    result.nil? ? 1 : result.children[1].children.first.content.scan(/(\d+)[^\d]*$/)[0][0].to_i
  end

end

class HWZScraper

  def self.scrape_thread_paths(forum_path, &block)
    req = HWZRequest.new
    yield req.get_thread_paths(forum_path)
  end

  def self.scrape_thread_comments(thread_path, output_path)
    req = HWZRequest.new
    resp = req.get_comments(thread_path)
    save!(output_path, resp)
  end

  def self.save!(filepath, data)
    File.open(filepath, 'a') do |f|
      data.each { |e| f.puts e }
    end
  end

end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby scrape.rb [options]"

  opts.on("-o", "--output [filename]", String, "Output file. Default: 'data.txt'") do |o|
    options[:output_path] = o
  end

  opts.on("-t", "--threads [threads]", Integer, "Number of threads for multithreading. Default: 15") do |t|
    options[:threads] = t
  end

  opts.on("-p", "--pages [pages]", Integer, "Number of pages to scrape (latest). Default: 100") do |l|
    options[:pages] = l
  end
end.parse!

pool = Concurrent::FixedThreadPool.new(options.fetch(:threads, 15))
pool2 = Concurrent::FixedThreadPool.new(options.fetch(:threads, 15))

forums = { edmw: 'eat-drink-man-woman-16' }

1.upto(options.fetch(:pages, 100).to_i) do |i|
  pool.post do 
    page_url = forums[:edmw] + (i == 1 ? "" : "/index#{i}.html")
    HWZScraper.scrape_thread_paths(page_url) do |paths|
      puts "Thread paths pulled from page: #{i}"
      paths.each do |path|
        pool2.post do
          HWZScraper.scrape_thread_comments(path, options.fetch(:output_path, 'data.txt'))
          puts "Thread posts scraped: #{path}"
        end
      end
    end
  end
end

pool.shutdown
pool.wait_for_termination
pool2.shutdown
pool2.wait_for_termination
