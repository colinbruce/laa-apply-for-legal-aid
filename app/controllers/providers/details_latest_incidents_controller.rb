module Providers
  class DetailsLatestIncidentsController < ProviderBaseController
    def show
      authorize legal_aid_application
      @form = Incidents::LatestIncidentForm.new(model: incident)
    end

    def update
      authorize legal_aid_application
      @form = Incidents::LatestIncidentForm.new(form_params)
      render :show unless save_continue_or_draft(@form)
    end

    private

    def incident
      legal_aid_application.latest_incident || legal_aid_application.build_latest_incident
    end

    def form_params
      merge_with_model(incident) do
        params.require(:incident).permit(
          :occurred_day, :occurred_month, :occurred_year, :details
        )
      end
    end
  end
end
