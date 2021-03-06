require "lita"

module Lita
  module Handlers
    class GoogleImages < Handler
      URL = "https://ajax.googleapis.com/ajax/services/search/images"

      route(/(?:image|img)(?:\s+me)? (.+)/, :fetch, command: false, help: {
        ":image QUERY" => "Displays a random image from Google Images matching the query."
      })

      route(/(?:imagebomb|imgbomb)(?:\s+me)? (.+)/, :fetch_many, command: false, help: {
        ":imagebomb QUERY" => "Displays 6 random images from Google Images matching the query."
      })

      def self.default_config(handler_config)
        handler_config.safe_search = :active
      end

      def fetch(response)
        query = response.matches[0][0]

        http_response = http.get(
          URL,
          v: "1.0",
          q: query,
          safe: safe_value,
          rsz: 8
        )

        data = MultiJson.load(http_response.body)

        if data["responseStatus"] == 200
          choice = data["responseData"]["results"].sample
          if choice
            response.reply "#{choice["unescapedUrl"]}#.png"
          else
            response.reply %{No images found for "#{query}".}
          end
        else
          reason = data["responseDetails"] || "unknown error"
          Lita.logger.warn(
            "Couldn't get image from Google: #{reason}"
          )
        end
      end

      def fetch_many(response)
        query = response.matches[0][0]

        http_response = http.get(
          URL,
          v: "1.0",
          q: query,
          safe: safe_value,
          rsz: 8
        )

        data = MultiJson.load(http_response.body)

        if data["responseStatus"] == 200
          images = data["responseData"]["results"].to_a.shuffle[0..5]
          if images
            images.each do |image|
              response.reply "#{image["unescapedUrl"]}#.png"
            end
          else
            response.reply %{No images found for "#{query}".}
          end
        else
          reason = data["responseDetails"] || "unknown error"
          Lita.logger.warn(
            "Couldn't get image from Google: #{reason}"
          )
        end
      end

      private

      def safe_value
        safe = Lita.config.handlers.google_images.safe_search || "active"
        safe = safe.to_s.downcase
        safe = "active" unless ["active", "moderate", "off"].include?(safe)
        safe
      end
    end

    Lita.register_handler(GoogleImages)
  end
end
