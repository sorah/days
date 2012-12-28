require 'active_record'
require 'stringex'
require 'redcarpet'

module Days
  class Entry < ActiveRecord::Base
    attr_accessible :title, :body, :slug, :published_at, :categories, :user

    validates_uniqueness_of :slug
    validates_presence_of :title, :body, :rendered, :slug

    belongs_to :user, class_name: 'Days::User'
    has_and_belongs_to_many :categories, class_name: 'Days::Category'

    before_validation do
      if self.title && !self.slug
        self.slug = self.title.to_url
      end
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
        :autolink => true, :space_after_headers => true,
        :no_intra_emphasis => true, :fenced_code_blocks => true,
        :tables => true, :superscript => true)
      self.rendered = markdown.render(self.body)
    end
  end
end
