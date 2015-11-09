# -*- coding: utf-8 -*-
require 'mechanize'
require 'addressable/uri'

module GitTrend
  class Scraper
    BASE_HOST = 'https://github.com'
    BASE_URL = "#{BASE_HOST}/trending"

    def initialize
      @agent = Mechanize.new
      @agent.user_agent = "git-trend #{VERSION}"
      proxy = URI.parse(ENV['http_proxy']) if ENV['http_proxy']
      @agent.set_proxy(proxy.host, proxy.port, proxy.user, proxy.password) if proxy
    end

    def get(language = nil, since = nil, number = nil)
      page = @agent.get(generate_url_for_get(language, since))
      projects = generate_project(page)
      fail ScrapeException if projects.empty?
      number ? projects[0...number] : projects
    end

    def languages
      languages = []
      page = @agent.get(BASE_URL)
      page.search('div.select-menu-item a').each do |content|
        href = content.attributes['href'].value
        # objective-c++ =>
        language = href.match(%r{github.com/trending\?l=(.+)}).to_a[1]
        languages << CGI.unescape(language) if language
      end
      languages
    end

    private

    def generate_url_for_get(language, since)
      uri = Addressable::URI.parse(BASE_URL)
      if language || since
        uri.query_values = { l: language, since: since }.delete_if { |_k, v| v.nil? }
      end
      uri.to_s
    end

    def extract_lang_and_star_from_meta(text)
      meta_data = text.split('•').map { |x| x.delete("\n").strip }
      if meta_data.size == 3
        lang = meta_data[0]
        star_count = meta_data[1].delete(',').to_i
        [lang, star_count]
      else
        star_count = meta_data[0].delete(',').to_i
        ['', star_count]
      end
    end

    def generate_project(page)
      page.search('.repo-list-item').map do |content|
        project = Project.new
        meta_data = content.search('.repo-list-meta').text
        project.lang, project.star_count = extract_lang_and_star_from_meta(meta_data)
        project.name        = content.search('.repo-list-name a').text.split.join
        project.description = content.search('.repo-list-description').text.delete("\n").strip
        project
      end
    end
  end
end
