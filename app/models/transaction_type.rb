class TransactionType < ApplicationRecord
  # Note that names should be unique across the whole of NAMES - so both credit and debit
  NAMES = {
    credit: %i[
      salary benefits
      maintenance_in
      property_or_lodger
      student_loan
      pension
      fiends_or_family
    ],
    debit: %i[
      rent_or_mortgage
      council_tax
      child_care
      maintenance_out
      legal_aid
    ]
  }.freeze

  scope :debits, -> { where(operation: :debit) }
  scope :credits, -> { where(operation: :credit) }

  def self.populate
    existing = pluck(:name).map(&:to_sym)
    NAMES.each do |operation, names|
      (names - existing).each { |name| create!(name: name, operation: operation) }
    end
  end

  def label_name
    I18n.t("transaction_types.names.#{name}")
  end
end
