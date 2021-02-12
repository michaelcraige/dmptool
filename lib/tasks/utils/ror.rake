# frozen_string_literal: true

namespace :ror do

  desc "Populate the org_indices table from latest tmp/ror.json (single use) To force it to reprocess you can pass an argument `rails \"ror:index[true]\"` (Note the quotes)"
  task :index, [:force] => :environment do |_, args|
    ExternalApis::RorService.fetch(force: args[:force])
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
    p "SUPER SEARCH for 'UCB' - #{Time.now.strftime('%H:%m:%S')}"
    results = OrgSelection::NewSearchService.super_search(term: "UCB")
    pp results.map { |r| "#{r.users.length} - #{r.name}" }[0..10]
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 10 of #{results.length}"
    p ""
    p '============================================================='
    p ""
    p "Searching for 'UCB' - #{Time.now.strftime('%H:%m:%S')}"
    results = OrgSelection::NewSearchService.search(term: "UCB")
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 10 of #{results.length}"

    p results.first.inspect

    pp results.map(&:name)[0..10]
    p ""
    p "Old Way - #{Time.now.strftime('%H:%m:%S')}"
    results = OrgSelection::SearchService.search_combined(search_term: "UCB")
    p "Done: - #{Time.now.strftime('%H:%m:%S')}- Showing top 10 of #{results.length}"
    pp results.map { |r| r[:name] }[0..10]
  end
end
