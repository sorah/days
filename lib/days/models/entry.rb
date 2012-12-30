require 'active_record'
require 'stringex'
require 'redcarpet'

module Days
  class Entry < ActiveRecord::Base
    attr_accessible :title, :body, :slug, :published_at, :categories, :user, :draft

    validates_uniqueness_of :slug
    validates_presence_of :title, :body, :rendered, :slug

    belongs_to :user, class_name: 'Days::User'
    has_and_belongs_to_many :categories, class_name: 'Days::Category'

    scope :published, -> do
      where('published_at IS NOT NULL AND published_at <= ?', Time.now).
      order('published_at DESC')
    end

    def draft=(x)
      if x.present?
        @draft = true
      else
        @draft = false
      end
    end

    def draft?
      @draft
    end
    alias draft draft?

    def published?
      self.published_at && self.published_at <= Time.now
    end

    def scheduled?
      self.published_at && Time.now < self.published_at
    end

    before_validation do
      if draft?
        self.published_at = nil
      else
        self.published_at ||= Time.now
      end

      if self.title && (!self.slug || self.slug.empty?)
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
