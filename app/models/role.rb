class Role < ApplicationRecord
  has_many :firm_roles
  has_many :firms, through: :firm_roles
  has_many :provider_roles
  has_many :proiders, through: :provider_roles
end
