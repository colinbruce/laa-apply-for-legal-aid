module Settings
  class SettingForm
    include BaseForm

    form_for Setting

    attr_accessor :mock_true_layer_data,
                  :allow_non_passported_route,
                  :manually_review_all_cases,
                  :welsh_translation

    validates :mock_true_layer_data,
              :allow_non_passported_route,
              :manually_review_all_cases,
              :welsh_translation,
              presence: true
  end
end
