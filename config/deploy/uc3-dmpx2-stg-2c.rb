# rubocop:disable Naming/FileName
# frozen_string_literal: true

set :application, "DMPTool"
set :repo_url, "https://github.com/CDLUC3/dmptool.git"

set :server_host, ENV["SERVER_HOST"] || "uc3-dmpx2-stg-2c.cdlib.org"
server fetch(:server_host), user: "dmp", roles: %w[web app db]

set :deploy_to, "/dmp/apps/dmp"
set :share_to, "dmp/apps/dmp/shared"

# Define the location of the private configuration repo
set :config_branch, "uc3-dmpx2-stg"

set :rails_env, "stage"
# rubocop:enable Naming/FileName
