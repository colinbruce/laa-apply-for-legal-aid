class ProviderRole < ApplicationRecord
  belongs_to :provider
  belongs_to :role
end
