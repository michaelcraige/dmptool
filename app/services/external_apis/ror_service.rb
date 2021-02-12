# frozen_string_literal: true

module ExternalApis

  # This service provides an interface to the Research Organization Registry (ROR)
  # API.
  # For more information: https://github.com/ror-community/ror-api
  class RorService < BaseService

    ROR_JSON = Rails.root.join("tmp", "ror.json").freeze
    ROR_TSTAMP = Rails.root.join("tmp", "last_ror").freeze

    class << self

      # Retrieve the config settings from the initializer
      def landing_page_url
        Rails.configuration.x.ror&.landing_page_url || super
      end

      def api_base_url
        Rails.configuration.x.ror&.api_base_url || super
      end

      def max_pages
        Rails.configuration.x.ror&.max_pages || super
      end

      def max_results_per_page
        Rails.configuration.x.ror&.max_results_per_page || super
      end

      def max_redirects
        Rails.configuration.x.ror&.max_redirects || super
      end

      def active?
        Rails.configuration.x.ror&.active || super
      end

      def heartbeat_path
        Rails.configuration.x.ror&.heartbeat_path
      end

      def search_path
        Rails.configuration.x.ror&.search_path
      end


      def fetch(force: false)
        # TODO: At some point find a way to retrieve the latest zip file
        #       They are current stored as zip files within the GitHub repo:
        #       https://github.com/ror-community/ror-api/tree/master/rorapi/data
        #
        # TODO: Write the downloaded json file to the tmp/ dir
        file = File.new(ROR_JSON, "r")
        mod_date = file.mtime
        # Create the timestamp file if it is not present
        ror_tstamp = File.open(ROR_TSTAMP, "w+") unless File.exist?(ROR_TSTAMP) && !force
        ror_tstamp = File.open(ROR_TSTAMP, "r+") unless ror_tstamp.present?

        if file.present?
          if mod_date.to_s == ror_tstamp.read
            p "ROR file already processed: #{mod_date.to_s}"
          else
            p "ROR processing new file: #{mod_date.to_s}"
            if process_ror_file(file: file, time: mod_date)
              f = File.open(ROR_TSTAMP, "w")
              f.write(mod_date.to_s)
            else
              p "An error occurred while processing the file!"
            end
          end
        end
      end

      # Ping the ROR API to determine if it is online
      #
      # @return true/false
      def ping
        return true unless active? && heartbeat_path.present?

        resp = http_get(uri: "#{api_base_url}#{heartbeat_path}")
        resp.present? && resp.code == 200
      end

      # Search the ROR API for the given string.
      #
      # @return an Array of Hashes:
      # {
      #   id: 'https://ror.org/12345',
      #   name: 'Sample University (sample.edu)',
      #   sort_name: 'Sample University',
      #   score: 0
      #   weight: 0
      # }
      # The ROR limit appears to be 40 results (even with paging :/)
      def search(term:, filters: [])
        return [] unless active? && term.present? && ping

        process_pages(
          term: term,
          json: query_ror(term: term, filters: filters),
          filters: filters
        )

      # If a JSON parse error occurs then return results of a local table search
      rescue JSON::ParserError => e
        log_error(method: "ROR search", error: e)
        []
      end

      private

      # Queries the ROR API for the sepcified name and page
      def query_ror(term:, page: 1, filters: [])
        return [] unless term.present?

        # build the URL
        target = "#{api_base_url}#{search_path}"
        query = query_string(term: term, page: page, filters: filters)

        # Call the ROR API and log any errors
        resp = http_get(uri: "#{target}?#{query}", additional_headers: {},
                        debug: false)

        unless resp.present? && resp.code == 200
          handle_http_failure(method: "ROR search", http_response: resp)
          return []
        end
        JSON.parse(resp.body)
      end

      # Build the query string using the search term, current page and any
      # filters specified
      def query_string(term:, page: 1, filters: [])
        query_string = ["query=#{term}", "page=#{page}"]
        query_string << "filter=#{filters.join(',')}" if filters.any?
        query_string.join("&")
      end

      # Recursive method that can handle multiple ROR result pages if necessary
      def process_pages(term:, json:, filters: [])
        return [] if json.blank?

        results = parse_results(json: json)
        num_of_results = json.fetch("number_of_results", 1).to_i

        # Determine if there are multiple pages of results
        pages = (num_of_results / max_results_per_page.to_f).to_f.ceil
        return results unless pages > 1

        # Gather the results from the additional page (only up to the max)
        (2..(pages > max_pages ? max_pages : pages)).each do |page|
          json = query_ror(term: term, page: page, filters: filters)
          results += parse_results(json: json)
        end
        results || []

      # If we encounter a JSON parse error on subsequent page requests then just
      # return what we have so far
      rescue JSON::ParserError => e
        log_error(method: "ROR search", error: e)
        results || []
      end

      # Convert the JSON items into a hash
      def parse_results(json:)
        results = []
        return results unless json.present? && json.fetch("items", []).any?

        json["items"].each do |item|
          next unless item["id"].present? && item["name"].present?

          results << {
            ror: item["id"].gsub(/^#{landing_page_url}/, ""),
            name: org_name(item: item),
            sort_name: item["name"],
            url: item.fetch("links", []).first,
            language: org_language(item: item),
            fundref: fundref_id(item: item),
            abbreviation: item.fetch("acronyms", []).first
          }
        end
        results
      end

      # Org names are not unique, so include the Org URL if available or
      # the country. For example:
      #    "Example College (example.edu)"
      #    "Example College (Brazil)"
      def org_name(item:)
        return "" unless item.present? && item["name"].present?

        country = item.fetch("country", {}).fetch("country_name", "")
        website = org_website(item: item)
        # If no website or country then just return the name
        return item["name"] unless website.present? || country.present?

        # Otherwise return the contextualized name
        "#{item['name']} (#{website || country})"
      end

      # Extracts the org's ISO639 if available
      def org_language(item:)
        dflt = I18n.default_locale || "en"
        return dflt unless item.present?

        labels = item.fetch("labels", [{ "iso639": dflt }])
        labels.first&.fetch("iso639", I18n.default_locale) || dflt
      end

      # Extracts the website domain from the item
      def org_website(item:)
        return nil unless item.present? && item.fetch("links", [])&.any?
        return nil if item["links"].first.blank?

        # A website was found, so extract just the domain without the www
        domain_regex = %r{^(?:http://|www\.|https://)([^/]+)}
        website = item["links"].first.scan(domain_regex).last.first
        website.gsub("www.", "")
      end

      # Extracts the FundRef Id if available
      def fundref_id(item:)
        return "" unless item.present? && item["external_ids"].present?
        return "" unless item["external_ids"].fetch("FundRef", {}).any?

        # If a preferred Id was specified then use it
        ret = item["external_ids"].fetch("FundRef", {}).fetch("preferred", "")
        return ret if ret.present?

        # Otherwise take the first one listed
        item["external_ids"].fetch("FundRef", {}).fetch("all", []).first
      end



      def process_ror_file(file:, time:)
        return false unless file.present?

        json = JSON.parse(file.read)
        cntr = 0
        total = json.length
        json.each do |hash|
          cntr += 1
          p "    processed #{cntr} out of #{total} records" if cntr % 1000 == 0
          unless process_ror_record(record: hash, time: time)
            p "        unable to process record for: '#{hash&.fetch("name", "unknown")}'"
          end
        end
        # Remove any old ROR records (their file_timestamps would not have been updated)
        # Note this does not remove any associated Org records!
        OrgIndex.where("file_timestamp < #{mod_date.to_s}").destroy_all
        true
      rescue JSON::ParserError => e
        log_error(method: "RORService.process_ror_file", error: e)
        false
      end

      def process_ror_record(record:, time:)
        return nil unless record.present? && record.is_a?(Hash) && record["id"].present?

        org_index = OrgIndex.find_or_create_by(ror_id: record["id"])

        fundref_ids = record.fetch("external_ids", {}).fetch("FundRef", {})
        fundref = fundref_ids.fetch("preferred", fundref_ids.fetch("all", []).first)
        fundref = "https://doi.org/10.13039/#{fundref}" if fundref.present?

        # Grab the domain
        domain_regex = %r{^(?:http://|www\.|https://)([^/]+)}
        link = record.fetch("links", []).first
        domain = link&.scan(domain_regex)&.last&.first&.gsub("www.", "")
        name = [record["name"], domain.present? ? "(#{domain})" : ""].join(" ")

        org_index.acronyms = record["acronyms"]
        org_index.aliases = record["aliases"]
        org_index.country = record["country"]
        org_index.types = record["types"]
        org_index.file_timestamp = time
        org_index.fundref_id = fundref
        org_index.home_page = link.present? && link.length < 255 ? link : nil
        # If its already associated with an Org don't change the name!
        org_index.name = safe_string(value: name) unless org_index.org_id.present?
        org_index.save
        true
      rescue StandardError => e
        log_error(method: "RorService.process_ror_record", error: e)
        false
      end

      def safe_string(value:)
        return value if value.blank? || value.length < 255

        value[0..254]
      end

    end

  end

end
