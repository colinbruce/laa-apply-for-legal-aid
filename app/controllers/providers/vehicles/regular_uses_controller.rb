module Providers
  module Vehicles
    class RegularUsesController < ProviderBaseController
      prefix_step_with :vehicles

      def show
        authorize legal_aid_application
        @form = VehicleForm::UsedRegularlyForm.new(model: vehicle)
      end

      def update
        authorize legal_aid_application
        @form = VehicleForm::UsedRegularlyForm.new(form_params)
        render :show unless save_continue_or_draft(@form)
      end

      private

      def vehicle
        @vehicle ||= legal_aid_application.vehicle
      end

      def form_params
        merge_with_model(vehicle) do
          { used_regularly: params[:used_regularly] }
        end
      end
    end
  end
end
