# Days

[![Build Status](https://travis-ci.org/sorah/days.png?branch=master)](https://travis-ci.org/sorah/days)

Days is simple blog system built up with Sinatra.

## Development status

- Currently `master` branch is in active development, really unstable
  - Any documentation can easily be outdated.
  - See [v0.2.0](https://github.com/sorah/days/tree/v0.2.0) tree for the stable information.

## Installation

    $ gem install days

## Set up

    $ mkdir foo && cd foo
    $ days init
    $ days migration

### Start development server

    $ days server

Access `/admin/setup` path to setup admin user.

## Configuration

edit `config.yml`. We're using [settingslogic](https://github.com/binarylogic/settingslogic) to use namespace based on environment.

* `permalink`: URL Style for permalink. String like `{TAG}` in URL will replaced with something.

  * Example: `/{year}/{month}/{id}-{slug}` with entry published in Jan 2013, slug: `slug` and id: `42` → `/2013/01/42-slug`
  * `{slug}` - entry slug
  * `{id}` - entry id
  * `{year}` - year that entry published
  * `{month}` - month that entry published
  * `{day}` - day that entry published
  * `{hour}` - hour that entry published
  * `{minute}` - minute that entry published
  * `{second}` - second that entry published

* `title`: Your blog title.
* `database`: Database configuration. This will be passed to `ActiveRecord::Base.establish_connection`.

## Deploy

Days is basically Rack app, so you can deploy using thin, unicorn, and puma, etc.

### Deploy to Heroku

First, prepare days app repository

    $ days init
    $ vim config.yml

    ...
    group :production do
      gem "pg"
    end
    ...

    $ bundle install --without production
    $ git init && git add . && git commit -m 'initial'

Then, create heroku apps and prepare heroku postgres database:

    $ heroku apps:create
    $ heroku addons:add heroku-postgresql:dev && heroku pg:wait
    $ heroku pg:promote `heroku config | grep HEROKU_POSTGRESQL|cut -d: -f 1`

Next, push repository to heroku.

    $ git push -u heroku master

Finally, migrate the DB and restart the app.

    $ heroku run days migrate production
    $ heroku restart

Now, you can access to your new blog by:

    $ heroku apps:open

Access `/admin/setup` path to setup admin user.

## Contributing

Fork and give me pull-request, please!

## To-dos

* Plugins
