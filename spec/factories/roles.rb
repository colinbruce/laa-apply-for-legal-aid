FactoryBot.define do
  factory :role do
    sequence(:role) { |n| "application.role.#{n}" }
    sequence(:description) { |n| "This is the description for application.role.#{n}" }
  end

  trait :application_passported do
    role { 'application.passported.*' }
    description { 'Can create, modify, delete passported applications' }
  end

  trait :application_non_passported do
    role { 'application.non_passported.*' }
    description { 'Can create, modify, delete non-passported applications' }
  end
end
