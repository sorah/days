require 'days/models/base'
require 'html/pipeline'
require 'stringex'

module Days
  class Entry < Days::Models::Base
    #attr_accessible :title, :body, :slug, :published_at, :categories, :user, :draft, :old_path

    validates_uniqueness_of :slug
    validates_presence_of :title, :body, :rendered, :slug

    belongs_to :user, class_name: 'Days::User'
    has_and_belongs_to_many :categories, class_name: 'Days::Category'

    scope :published, -> do
      includes(:categories).
      where('published_at IS NOT NULL AND published_at <= ?', Time.now).
      order('published_at DESC')
    end

    scope :draft, -> do
      where(published_at: nil)
    end

    scope :scheduled, -> do
      includes(:categories).
      where('published_at IS NOT NULL AND published_at >= ?', Time.now).
      order('published_at DESC')
    end

    paginates_per 12

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

    def short_rendered
      self.rendered.gsub(/<!-- *more *-->.+\z/m, block_given? ? yield(self) : '')
    end

    def body=(*)
      @need_rendering = true
      super
    end

    def self.default_pipeline
      HTML::Pipeline.new([
        HTML::Pipeline::MarkdownFilter,
      ], unsafe: true, commonmarker_extensions:  %i[table strikethrough autolink])
    end

    def pipeline=(other)
      @pipeline = other
    end

    def pipeline
      @pipeline ||= self.class.default_pipeline
    end

    def render!(pipeline: self.pipeline)
      result = pipeline.call(self.body)
      self.rendered = result[:output].to_s
      @need_rendering = false
      nil
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

      self.render! if @need_rendering
    end
  end
end
