# frozen_string_literal: true

class OrgIndicesController < ApplicationController

  # GET orgs/search
  def search
    term = org_index_params.fetch(:org_index, {})[:name]
    @context = org_index_params[:context]
    @orgs = OrgIndex.search(
      term, org_index_params[:known_only] == "true", org_index_params[:funder_only] == "true"
    )
  end

  private

  def org_index_params
    params.permit(%i[known_only funder_only context], org_index: :name)
  end

end
