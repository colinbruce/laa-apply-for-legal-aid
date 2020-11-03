module Admin
  class AdminBaseController < ApplicationController
    before_action :check_vpn_ipaddr, :authenticate_admin_user!
    layout 'admin'.freeze

    protected

    def check_vpn_ipaddr
      redirect_to error_path(:access_denied) unless ip_addr_authorised?(current_ip_address)
    end

    def current_ip_address
      request.env['HTTP_X_REAL_IP'] || request.env['REMOTE_ADDR']
    end

    def ip_addr_authorised?(string_ipaddr)
      ip_checker = AuthorizedIpRanges.new
      ip_checker.authorized?(string_ipaddr)
    end
  end
end
