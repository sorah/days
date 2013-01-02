require 'active_record'
require 'json'

ActiveRecord::Base.establish_connection ENV["DATABASE_URL"]

class User < ActiveRecord::Base
  has_many :entries
end

class Category < ActiveRecord::Base
  has_many :entries
end

class Entry < ActiveRecord::Base
  belongs_to :user
  belongs_to :category
end

class Post < Entry
end

Post.order('id ASC').all.each do |post|
  if 'kramdown' != post.markup
    warn "WARN: #{post.slug} (#{post.id}) is not written in kramdown"
  end

  hash = {}
  hash[:id] = post.id
  hash[:user] = post.user.name
  hash[:slug] = post.slug
  hash[:title] = post.title
  hash[:body] = post.body
  if post.draft == 1
    hash[:published_at] = post.created_at
  else
    hash[:published_at] = nil
    hash[:draft] = true
  end
  if post.category
    hash[:category] = [post.category.title]
  else
    hash[:category] = []
  end
  puts hash.to_json
end
