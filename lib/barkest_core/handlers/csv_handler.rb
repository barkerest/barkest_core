require 'csv'

module BarkestCore

  ##
  # Handles CSV views.
  module CsvHandler
    # :enddoc:

    class CsvGenerator
      def self.generate
        file = CSV.generate do |csv|
          yield csv
        end
        file.html_safe
      end
    end

    class Handler
      def self.call (template)
        %{
          BarkestCore::CsvHandler::CsvGenerator.generate do |csv|
            #{template.source}
          end
        }
      end
    end
  end

end
