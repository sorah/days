%w[
  user
  category
  category_entry
  entry
].each do |m|
  require "days/models/#{m}"
end
