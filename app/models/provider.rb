class Provider < ApplicationRecord
  devise :saml_authenticatable, :trackable
  serialize :roles
  serialize :offices

  belongs_to :firm
  belongs_to :selected_office, class_name: :Office, foreign_key: :selected_office_id, optional: true
  has_many :legal_aid_applications
  has_and_belongs_to_many :offices

  has_many :provider_roles
  has_many :roles, through: :provider_roles

  after_create do
    ActiveSupport::Notifications.instrument 'dashboard.provider_created'
  end

  after_save :normalize_roles

  delegate :name, to: :firm, prefix: true, allow_nil: true

  def update_details
    return update_details_directly unless firm

    ProviderDetailsCreatorWorker.perform_async(id)
  end

  def update_details_directly
    ProviderDetailsCreator.call(self)
  end

  def whitelisted_user?
    whitelisted_users&.any? { |user| user.casecmp(username).zero? }
  end

  def user_roles
    roles.empty? ? firm.roles : roles
  end

  private

  def whitelisted_users
    Rails.configuration.x.application.whitelisted_users
  end

  def normalize_roles
    roles.map(&:destroy) if roles.sort == firm.roles.sort
  end
end
