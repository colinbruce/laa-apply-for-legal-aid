module DependantHelper
  ATTRIBUTES = %i[
    name
    date_of_birth
    relationship
    in_full_time_education
    income
    assets
  ].freeze

  def dependant_hash(dependant)
    items = dependant_as_array(dependant)
    items&.compact!
    return nil unless items.present?

    {
      items: items
    }
  end

  def dependant_as_array(dependant)
    ATTRIBUTES&.map do |attribute|
      send(attribute, dependant)
    end
  end

  def name(dependant)
    build_ostruct(
      t('name', scope: 'providers.means_summaries.show.dependants'),
      dependant.name
    )
  end

  def date_of_birth(dependant)
    build_ostruct(
      t('date_of_birth', scope: 'providers.means_summaries.show.dependants'),
      dependant.date_of_birth
    )
  end

  def relationship(dependant)
    build_ostruct(
      t('relationship', scope: 'providers.means_summaries.show.dependants'),
      dependant.relationship.nil? ? '' : t(dependant.relationship, scope: 'shared.forms.dependants.relationship.option')
    )
  end

  def in_full_time_education(dependant)
    build_ostruct(
      t('in_full_time_education', scope: 'providers.means_summaries.show.dependants'),
      yes_no(dependant.in_full_time_education)
    )
  end

  def income(dependant)
    build_ostruct(
      t('income', scope: 'providers.means_summaries.show.dependants'),
      dependant.has_income? ? number_to_currency(dependant.monthly_income) : yes_no(dependant.has_income?)
    )
  end

  def assets(dependant)
    build_ostruct(
      t('assets', scope: 'providers.means_summaries.show.dependants'),
      dependant.has_assets_more_than_threshold? ? number_to_currency(dependant.assets_value) : yes_no(dependant.has_assets_more_than_threshold?)
    )
  end

  def build_ostruct(label, text)
    OpenStruct.new(
      label: label,
      amount_text: text
    )
  end
end
