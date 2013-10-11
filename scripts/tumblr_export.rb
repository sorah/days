require 'json'
require 'stringex'
require 'time'
require 'open-uri'

if ARGV.size < 1 || %w(--help -h).include?(ARGV[0])
  puts "Usage: #{File.basename __FILE__} tumblelog [api_key] [--ignore-ids]"
  puts ""
  puts "This exports your tumblelog for `days import`."
  puts "Exported texts will go STDOUT. Use redirection of your shell to save it."
  puts ""
  puts "When api_key not specified, this will see $TUMBLR_API_KEY, or ask to you."
  puts "Don't know how to Take API key? See here: http://www.tumblr.com/docs/en/api/v2#auth"
  puts ""
  puts "NOTE: This won't save images, and all other external resources. Just save texts, only."
  exit
end

def ask_for_key
  require 'io/console'
  abort "Can't access console, please specify your key via $TUMBLR_API_key or the 2nd argument" unless IO.console

  IO.console.print "Tumblr API Key: "
  IO.console.gets.chomp
end

def get_posts(tumblelog, key, offset=0)
  response = open("http://api.tumblr.com/v2/blog/#{tumblelog}/posts?api_key=#{key}&offset=#{offset}", 'r', &:read)
  JSON.parse(response)
end

ignore_id = !!ARGV.delete('--ignore-ids')
tumblelog = ARGV[0]
api_key = ARGV[1] || ENV["TUMBLR_API_KEY"] || ask_for_key

slugs = {}

offset = 0
loop do
  payload = get_posts(tumblelog, api_key, offset)
  break unless payload['response'] && payload['response']['posts']
  posts = payload['response']['posts']
  break if posts.empty?

  posts.each do |post|
    entry = {id: ignore_id ? post['id'].to_i : nil}
    entry[:title] = post['title']
    entry[:body] = post['body']
    entry[:published_at] = Time.parse(post['date']).localtime
    entry[:draft] = post['state'] != 'published'
    post_uri = URI.parse(post['post_url'])
    entry[:old_path] = post_uri.request_uri
    if %r{\A/post/(\d+?)/(.+)\z} === post_uri.request_uri
      entry[:slug] = $2
    end

    case post['type']
    when 'text'
      # do nothing
    when 'photo'
      warn "In post #{post['post_url']}, the following external resources won't be saved:"
      post['photos'].each { |_| warn"  - #{_['alt_sizes'][0]['url']}" }

      entry[:title] = post['caption'] ? post['caption'].dup : ''
      entry[:title].prepend('Photos: ')
      entry[:body] = <<-EOF
<section class="t-photos">
  <div class="t-photos-set">
  #{post['photos'].map { |_| photo = _['alt_sizes'][0]; "  <p><img src=\"#{photo['url']}\" width=\"#{_['width']}\" height=\"#{_['height']}\" alt=\"#{_['caption']}\"></p>" }.join("\n")}
  </div>
  <div class="t-photos-caption">
  #{post['caption']}
  </div>
</div>
      EOF
    when 'quote'
      entry[:title] = post['text'] ? post['text'].dup : ''
      entry[:title].prepend('Quote: ')
      if 20 < entry[:title].size
        entry[:title] = entry[:title][0, 20] + '...'
      end

      entry[:body] = <<-EOF
<section class="t-quote">
  <blockquote class="t-quote-text">
  #{post['text']}
  </blockquote>
  <div class="t-source">
  #{(post['source'] && !post['source'].empty?) ? post['source'] : "<a href=\"#{post['source_url']}\">#{post['source_title'] || post['source_url']}</a>"}
  </div>
</section>
      EOF
    when 'link'
      entry[:title].prepend('Quote: ')
      entry[:body] = <<-EOF
<section class="t-link">
  <div class="t-link-text">
    <a href="#{post['url']}">#{post['title']}</a>
  </div>
  <div class="t-link-description">
    #{post['description']}
  </div>
</section>
      EOF
    when 'chat'
      entry[:body] = <<-EOF
<section class="t-chat">
  #{ post['dialogue'].map { |d|
    "  <p><span class=\"t-chat-label\">#{d['label']}</span> <span class=\"t-chat-phrase\">#{d['phrase']}</span></p>"
  }.join("\n") }
</section>
      EOF
    when 'audio'
      warn "External Resource in #{post['post_url']} will be not saved"
      entry[:title] = post['caption'] ? post['caption'].dup : ''
      entry[:title].prepend('Audio: ')
      if 20 < entry[:title].size
        entry[:title] = entry[:title][0, 20] + '...'
      end

      entry[:body] = <<-EOF
<section class="t-audio">
  <div class="t-audio-player">#{post['player']}</div>
  <div class="t-audio-title">#{post['id3_title']}</title>
  <div class="t-source">
  #{(post['source'] && !post['source'].empty?) ? post['source'] : "<a href=\"#{post['source_url']}\">#{post['source_title'] || post['source_url']}</a>"}
  </div>
  <div class="t-caption">
  #{post['caption']}
  </div>
</section>
      EOF
    when 'video'
      warn "External Resource in #{post['post_url']} will be not saved"
      entry[:title] = post['caption'] ? post['caption'].dup : ''
      entry[:title].prepend('Audio: ')
      if 20 < entry[:title].size
        entry[:title] = entry[:title][0, 20] + '...'
      end

      entry[:body] = <<-EOF
<section class="t-video">
  <div class="t-video-player">#{post['player'][-1]['embed_code']}</div>
  <div class="t-source">
  #{(post['source'] && !post['source'].empty?) ? post['source'] : "<a href=\"#{post['source_url']}\">#{post['source_title'] || post['source_url']}</a>"}
  </div>
  <div class="t-caption">
  #{post['caption']}
  </div>
</section>
      EOF
    when 'answer'
      entry[:title] = post['question'] ? post['question'].dup : ''
      entry[:title].prepend('Answer for: ')
      if 20 < entry[:title].size
        entry[:title] = entry[:title][0, 20] + '...'
      end

      entry[:body] = <<-EOF
<section class="t-answer">
  <blockquote class="t-answer-question">#{post['question']}</div>
  <div class="t-source">
  from <a href="#{post['asking_url']}">#{post['asking_name']}</a>
  </div>
  <div class="t-answer-text">
  #{post['answer']}
  </div>
</section>
      EOF
    end

    if entry[:title].nil? || entry[:title].empty? || /\A\s*\z/ === entry[:title]
      entry[:title] = "#{(post['type'] || 'Post').capitalize} at #{post['date']}"
      entry[:slug] = "#{post['type'] || 'post'}-#{post['id']}"
    end

    entry[:slug] ||= entry[:title].to_url
    if slugs[entry[:slug]]
      entry[:slug].prepend "#{post['id']}-"
    end
    slugs[entry[:slug]] = true


    puts entry.to_json
  end

  offset += posts.size
end
