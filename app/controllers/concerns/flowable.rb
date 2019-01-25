module Flowable
  extend ActiveSupport::Concern

  included do
    delegate :back_path, :forward_path, to: :flow_service
    helper_method :back_path, :forward_path

    def go_forward
      if path?(forward_path)
        redirect_to forward_path
      else
        render plain: forward_path
      end
    end

    def flow_service
      @flow_service ||= Flow::BaseFlowService.flow_service_for(flow_module).new(
        params: params,
        legal_aid_application: legal_aid_application,
        current_step: controller_name.to_sym
      )
    end

    def flow_module
      @flow_module ||= self.class.parent.to_s.snakecase.to_sym
    end

    def path?(string)
      string.starts_with?('/')
    end
  end
end
