class Firm < ApplicationRecord
  has_many :offices
  has_many :providers
  has_many :legal_aid_applications, through: :providers
  has_many :firm_roles
  has_many :roles, through: :firm_roles

  after_create do
    ActiveSupport::Notifications.instrument 'dashboard.firm_created'
  end
end
