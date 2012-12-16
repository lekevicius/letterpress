module Jekyll

  require 'haml'
  require 'sass'
  require 'coffee-script'

  class HamlConverter < Converter
    safe true
    priority :normal

    def matches(ext)
      ext =~ /haml/i
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content)
      begin
        engine = Haml::Engine.new(content)
        engine.render
      rescue StandardError => e
          puts "HAML Error: " + e.message
      end
    end
  end

  class SassConverter < Converter
    safe true
    priority :normal

     def matches(ext)
      ext =~ /scss/i
    end

    def output_ext(ext)
      ".css"
    end

    def convert(content)
      begin
        engine = Sass::Engine.new(content, :syntax => :scss, :style => :compact)
        engine.render
      rescue StandardError => e
        puts "SASS Error: " + e.message
      end
    end
  end

  class CoffeeScriptConverter < Converter
    safe true
    priority :normal

    def matches(ext)
      ext =~ /coffee/i
    end

    def output_ext(ext)
      ".js"
    end

    def convert(content)
      begin
        CoffeeScript.compile content
      rescue StandardError => e
        puts "CoffeeScript Error:" + e.message
      end
    end
  end
end
