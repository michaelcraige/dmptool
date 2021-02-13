# frozen_string_literal: true

namespace :ror do

  desc "Populate the org_indices table from latest tmp/ror.json (single use) To force it to reprocess you can pass an argument `rails \"ror:index[true]\"` (Note the quotes)"
  task :index, [:force] => :environment do |_, args|
    p "Proccessing ROR catalog. See log/[env].log for details - #{Time.now.strftime('%H:%m:%S')}"
    ExternalApis::RorService.fetch(force: args[:force])
    p "Complete - #{Time.now.strftime('%H:%m:%S')}"
  end

  desc "Search"
  task search: :environment do
    # TODO: Convert this to a TEST!!!!
=begin
    p "Expecting to find 'UNSW Sydney (unsw.edu.au)' with an acronym of 'UNSW' and alias of 'University of New South Wales'"
    org = OrgIndex.find_by(name: "UNSW Sydney (unsw.edu.au)")
    p "By name 1 - #{OrgIndex.search("UNSW Sydney").include?(org)}"
    p "By name 2 - #{OrgIndex.search("Sydney").include?(org)}"
    p "By domain - #{OrgIndex.search("unsw.edu.au").include?(org)}"
    p "By acronym - #{OrgIndex.by_acronym("UNSW").include?(org)}"
    p "By alias 1 - #{OrgIndex.by_alias("University of New South Wales").include?(org)}"
    p "By alias 2 - #{OrgIndex.by_alias("New South Wales").include?(org)}"
    p "By type - #{OrgIndex.by_type("education").include?(org)}"
    p ""

    p "Searching for 'Berkeley' - #{Time.now.strftime('%H:%m:%S')}"
    results = OrgSelection::NewSearchService.search(term: "Berkeley")
    p "Done:  - #{Time.now.strftime('%H:%m:%S')} - Showing top 5 of #{results.length}"
    pp results.map(&:name)[0..5]
    p ""
    p "Old Way - #{Time.now.strftime('%H:%m:%S')}"
    results = OrgSelection::SearchService.search_combined(search_term: "Berkeley")
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 5 of #{results.length}"
    pp results.map { |r| r[:name] }[0..5]
    p ""
    p '============================================================='
    p ""
    p "Searching for 'Berk' - #{Time.now.strftime('%H:%m:%S')}"
    results = OrgSelection::NewSearchService.search(term: "Berk")
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 5 of #{results.length}"
    pp results.map(&:name)[0..5]
    p ""
    p "Old Way - #{Time.now.strftime('%H:%m:%S')}"
    results = OrgSelection::SearchService.search_combined(search_term: "Berk")
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 5 of #{results.length}"
    pp results.map { |r| r[:name] }[0..5]
    p '============================================================='
=end
    p ""
    s = Time.now
    p "NEW MODEL SEARCH for 'UCB' - #{s.strftime('%H:%m:%S')}"
    results = OrgIndex.search("UCB")
    e = Time.now - s
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 10 of #{results.length} (elapsed - #{e})"
    ucb = Org.where(abbreviation: "UCB").first
    p ucb.inspect
    p ucb&.users&.size
    pp results.map { |r| "#{r.users_count} - #{r.name}" }[0..14]
    p ""
    p '============================================================='
    p ""
    s = Time.now
    p "NEW SERVICE SEARCH for 'UCB' - #{s.strftime('%H:%m:%S')}"
    results = OrgSelection::NewSearchService.search(term: "UCB")
    e = Time.now - s
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 15 of #{results.length} (elapsed - #{e})"
    pp results.map(&:name)[0..14]
    p ""
    s = Time.now
    p "Old Way - (ROR and DB) #{s.strftime('%H:%m:%S')}"
    results = OrgSelection::SearchService.search_combined(search_term: "UCB")
    e = Time.now - s
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 15 of #{results.length} (elapsed - #{e})"
    pp results.map { |r| r[:name] }[0..14]
  end
end
