require "json"

module GitTrend::Formatters
  class JsonFormatter
    def print(projects, options)
      puts projects.map { |project| project.to_h }.to_json
    end

    def print_languages(languages)
      puts languages.to_json
    end
  end
end
