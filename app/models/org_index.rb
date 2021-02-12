# frozen_string_literal: true

# == Schema Information
#
# Table name: org_indices
#
#  id             :bigint(8)        not null, primary key
#  acronyms       :json
#  aliases        :json
#  country        :json
#  file_timestamp :time
#  home_page      :string
#  name           :string
#  types          :json
#  fundref_id     :string
#  org_id         :bigint
#  ror_id         :string
#
# Indexes
#
#  index_org_indices_on_fundref_id      (fundref_id)
#  index_org_indices_on_org_id          (org_id)
#  index_org_indices_on_ror_id          (ror_id)
#  index_org_indices_on_name            (name)
#  index_org_indices_on_file_timestamp  (file_timestamp)
#
class OrgIndex < ApplicationRecord

  # ================
  # = Associations =
  # ================

  belongs_to :org

  # ==========
  # = Scopes =
  # ==========

  scope :by_acronym, lambda { |term|
    where("LOWER(org_indices.acronyms) LIKE LOWER(?)", "%\"#{term}\"%")
  }

  scope :by_alias, lambda { |term|
    where("LOWER(org_indices.aliases) LIKE LOWER(?)", "%#{term}%")
  }

  scope :by_name, lambda { |term|
    where("LOWER(org_indices.name) LIKE LOWER(?)", "%#{term}%")
  }

  scope :by_type, lambda { |term|
    where("LOWER(org_indices.types) LIKE LOWER(?)", "%#{term}%")
  }

  scope :search, lambda { |term|
    by_name(term)
      .or(by_acronym(term))
      .or(by_alias(term))
  }

  scope :super_search, lambda { |term|
    results = by_name(term).or(by_acronym(term)).or(by_alias(term))

p "A: #{results.length}"

    results = results.map(&:to_org)

p "B: #{results.length}"

    # Also search the Orgs that have no association to this org_indices class
    results += Org.includes(:users).where.not(id: OrgIndex.all.pluck(:org_id)).search(term)

p "C: #{results.length}"

    results = sort_search_results(results: results, term: term)

p "D: #{results.length}"

    results
  }

  # ====================
  # = Instance methods =
  # ====================

  # Convert the record into a new Org
  def to_org
    return org if org.present?

    funder = fundref_id.present?
    institution = types.include?("Education")
    Org.new(
      name: name,
      abbreviation: acronyms.first&.upcase,
      contact_email: Rails.configuration.x.organisation.helpdesk_email,
      contact_name: _("%{app_name} helpdesk") % { app_name: ApplicationService.application_name },
      is_other: false,
      links: { "org": [{ "link": home_page, "text": "Home Page" }] },
      managed: false,
      target_url: home_page,
      funder: funder,
      institution: institution,
      organisation: !funder && !institution
    )
  end

  private

  class << self

    def sort_search_results(results:, term:)
      return [] unless results.is_a?(Array) && results.any? && term.present?

      results.sort { |a, b| weigh(term: term, org: b) <=> weigh(term: term, org: a) }
    end

    # Weighs the result. The lower the weight the closer the match
    def weigh(term:, org:)
      score = 0
      return score unless term.present? && org.present? && org.is_a?(Org)

      score += 1 if org.abbreviation == term.upcase
      score += 2 if org.name.downcase.start_with?(term.downcase)
      score += 1 if org.name.downcase.include?(term.downcase) && !org.name.downcase.start_with?(term.downcase)
      score
    end

  end

end
