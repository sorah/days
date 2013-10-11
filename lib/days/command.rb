require 'thor'
require 'fileutils'
require_relative 'config'
require_relative 'app'
require_relative 'migrator'

module Days
  class Command < Thor
    SKELETON_PATH = File.expand_path(File.join(__FILE__, '..', '..', '..', 'skeleton', 'days'))
    desc "init [DIR]", "Initialize days.gem world in the directory (default = ./)"
    def init(dir = ".")
      puts "Initializing new Days environment on #{File.expand_path dir}"
      FileUtils.cp_r Dir["#{SKELETON_PATH}/*"], "#{dir}/"
    end

    desc "init_theme [DIR]", "Generate template of theme (views) to DIR (default = ./)"
    def init_theme(dir = ".")
      if File.exists?(File.join(dir, 'views')) || File.exists?(File.join(dir, 'stylesheets'))
        puts "This will override the following:"
        puts "* #{dir}/views/entries.haml"
        puts "* #{dir}/views/entry.haml"
        puts "* #{dir}/views/layout.haml"
        puts "* #{dir}/stylesheets/style.scss"

        print "Continue (y/n)? "

        while _ = $stdin.gets
          case _
          when /^y|yes$/
            break
          when /^n|no$/
            puts 'Cancelled.'
            return
          else
            print "Please answer in 'yes' or 'no' or 'y' or 'n': "
          end
        end
      end

      require 'fileutils'

      root = File.expand_path(File.join(__FILE__, '..', '..', '..', 'app'))
      FileUtils.mkdir_p File.join(dir, 'views')
      FileUtils.mkdir_p File.join(dir, 'stylesheets')

      %w(entries.haml entry.haml layout.haml).each do |file|
        FileUtils.cp(File.join(root, 'views', file),
                     File.join(dir,  'views', file))
      end

      FileUtils.cp(File.join(root, 'stylesheets', 'style.scss'),
                   File.join(dir,  'stylesheets', 'style.scss'))
    end

    desc "server", "Starts the server"
    method_option :config, :type => :string, :aliases => "-c"
    method_option :port, :type => :numeric, :aliases => "-p", :default => 3162
    method_option :bind, :type => :string, :aliases => "-b", :default => nil
    method_option :environment, :type => :string, :aliases => "-e", :default => "development"
    method_option :pid, :type => :string, :aliases => "-c"
    def server
      set_env
      App.config = config
      rack_options = {
        app: App.rack,
        Port: options[:port],
        Host: options[:bind],
        daemonize: options[:daemonize],
        environment: options[:environment],
        server: options[:server],
      }
      rack_options.merge!(pid: File.expand_path(options[:pid])) if options[:pid]
      Rack::Server.start(rack_options)
    end

    # desc "precompile", "Precompile the assets for production"
    # method_option :config, :type => :string, :aliases => "-c"
    # def precompile
    # end

    desc "migrate [ENV]", "Run database migration for environment (default = development)"
    method_option :config, :type => :string, :aliases => "-c"
    method_option :version, :type => :numeric, :aliases => "-v", :default => nil
    method_option :scope, :type => :string, :aliases => "-s"
    method_option :verbose, :type => :boolean, :aliases => "-V", :default => true
    def migrate(env = "development")
      set_env env
      Days::Migrator.start(config, options)
    end

    desc "console [ENV]", "Start console using pry (default = development)"
    method_option :config, :type => :string, :aliases => "-c"
    def console(env = "development")
      set_env env
      require 'pry'
      require_relative 'models'
      config.establish_db_connection()
      Pry.start(binding)
    end

    desc "import FILE", "Import entries from file."
    method_option :config, :type => :string, :aliases => "-c"
    method_option :environment, :type => :string, :aliases => "-e", :default => "development"
    def import(file)
      set_env
      config.establish_db_connection()
      require 'json'
      users = {}
      categories = {}
      open(file, 'r') do |io|
        io.readlines.each do |line|
          line = JSON.parse(line)

          attributes ={}
          if line['id'] && Entry.where(id: line['id']).count.zero?
            new_id = line['id']
          else
            new_id = nil
          end

          if line['user']
            if users.has_key?(line['user'])
              user = users[line['user']]
            else
              user = users[line['user']] = User.where(login_name: line['user']).first
            end


            attributes[:user] = user if user
          end

          if line['category']
            attributes[:categories] = line['category'].map do |category_name|
              categories[category_name] ||= Category.find_or_create_by_name!(category_name)
            end
          end

          attributes[:slug] = line['slug'] if line['slug']
          attributes[:title] = line['title'] if line['title']
          attributes[:body] = line['body'] if line['body']
          attributes[:published_at] = line['published_at'] if line['published_at']
          attributes[:draft] = line['draft'] if line['draft']
          attributes[:old_path] = line['old_path'] if line['old_path']

          p attributes[:title]
          entry = Entry.new(attributes)
          entry.id = new_id if new_id
          entry.save!
        end
      end
    end

    private

    def set_env(env = nil)
      App.environment = env || options[:environment] || ENV["RACK_ENV"] || :development
    end

    def config
      @_days_config ||= Config.new(options[:config] || "./config.yml")
    end
  end
end
