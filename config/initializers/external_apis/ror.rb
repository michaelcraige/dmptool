# frozen_string_literal: true

# These configuration settings are used to communicate with the
# Research Organization Registry (ROR) API. For more information about
# the API and to verify that your configuration settings are correct,
# please refer to: https://github.com/ror-community/ror-api
Rails.configuration.x.ror.landing_page_url = "https://ror.org/"
Rails.configuration.x.ror.api_base_url = "https://api.ror.org/"
Rails.configuration.x.ror.full_catalog_file = Rails.root.join("tmp", "ror.json")
Rails.configuration.x.ror.catalog_process_date = Rails.root.join("tmp", "last_ror")
Rails.configuration.x.ror.active = true
