#!/bin/sh

if [ "$1" = "" ]; then
  to="sandbox"
else
  to="$1"
fi

if [ -d "${to}" ]; then
  echo "directory ./${to} already exists. quitting."
  exit 1
fi

echo "==> bundle install"
bundle install || exit 1
echo "==> mkdir $to && cd $to"
mkdir $to || exit 1
cd $to || exit 1
echo "===> bundle exec ../bin/days init"
bundle exec ../bin/days init || exit 1
echo "===> Replacing gemfile"
cat > Gemfile <<-EOF
source "https://rubygems.org"

gem "days", path: File.expand_path(File.join(__FILE__, '..', '..'))

group :production do
  # gem "mysql2"
end

group :development do
  gem "pry"
  gem "sqlite3"
end
EOF
echo "===> bundle install"
bundle install || exit 1
echo "===> bundle exec days migrate"
bundle exec days migrate || exit 1

echo "===== Days environment for development is set up at $(pwd)! ====="
