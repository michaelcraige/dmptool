# frozen_string_literal: true

class SuperAdmin::OrgSwapsController < ApplicationController

  after_action :verify_authorized

  def create
    # Allows the user to swap their org affiliation on the fly
    authorize current_user, :org_swap?
    begin
      @org = Org.find(org_swap_params[:org_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to(:back, alert: _("Please select an organisation from the list"))
      return
    end
    # rubocop:disable Metrics/LineLength
    if @org.present?
      current_user.org = @org
      if current_user.save
        redirect_to :back,
                    notice: _("Your organisation affiliation has been changed. You may now edit templates for %{org_name}.") % { org_name: current_user.org.name }
      else
        redirect_to :back,
                    alert: _("Unable to change your organisation affiliation at this time.")
      end
    else
      redirect_to :back, alert: _("Unknown organisation.")
    end
    # rubocop:enable Metrics/LineLength
  end

  private

  def org_swap_params
    params.require(:user).permit(:org_id, :org_name)
  end

end
