class CitizenEmailService
  include Rails.application.routes.url_helpers

  def initialize(application)
    @application = application
  end

  def send_email
    # Must use bang version `deliver_later!` or failures won't be retried by sidekiq
    NotifyMailer.citizen_start_email(*mailer_args).deliver_later!
    ActiveSupport::Notifications.instrument 'dashboard.applicant_emailed', legal_aid_application_id: @application.id
  end

  private

  attr_reader :application

  def mailer_args
    [
      application.application_ref,
      applicant.email_address,
      application_url,
      applicant.full_name,
      provider.firm.name
    ]
  end

  def provider
    application&.provider
  end

  def application_url
    @application_url ||= citizens_legal_aid_application_url(secure_id)
  end

  def applicant
    @applicant ||= application&.applicant
  end

  def secure_id
    application.generate_secure_id
  end
end
