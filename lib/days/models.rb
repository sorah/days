%w[
  user
  category
  entry
].each do |m|
  require "days/models/#{m}"
end
