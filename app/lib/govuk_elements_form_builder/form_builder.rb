module GovukElementsFormBuilder
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Prevents surrounding of erroneous inputs with <div class="field_with_errors">
    # https://guides.rubyonrails.org/configuring.html#configuring-action-view
    ActionView::Base.field_error_proc = proc { |html_tag| html_tag.html_safe }

    delegate :content_tag, to: :@template
    delegate :errors, to: :@object

    # Usage:
    # <%= form.govuk_text_field :name %>
    # <%= form.govuk_text_area :statement %>
    #
    # You can specify the label and hint copies:
    # e.g., <%= form.govuk_text_field :name, label: 'Enter your name', hint: 'Your real name' %>
    #
    # Otherwise, label and hints are to be defined in the locale file:
    # 'helpers.hint.user.name'
    # 'helpers.label.user.name'
    #
    # Use the "hint: nil" option to not display the hint message.
    # e.g., <%= form.govuk_text_field :name, hint: nil %>
    #
    # Use the "label: nil" option to not display a label.
    # e.g., <%= form.govuk_text_field :name, label: nil, hint: 'hint text' %>
    #
    # Use the :input_prefix to insert a character inside and at the beginning of the input field.
    # e.g., <%= form.govuk_text_field :property_value, input_prefix: '$' %>
    #
    # Use :field_with_error to have the input be marked as erroneous when an other attribute has an error.
    # e.g., <%= form.govuk_text_field :address_line_two, field_with_error: :address_line_one %>
    #
    %w[text_field file_field text_area].each do |text_input|
      define_method("govuk_#{text_input}") do |attribute, options = {}|
        input_helper.__send__(text_input, attribute, options)
      end
    end

    # Usage:
    # <%= form.govuk_radio_button(:gender, 'm')
    # <%= form.govuk_radio_button(:gender, 'm', label: 'Male')
    #
    # If label is not specified, it will be grabbed from the locale file at:
    # 'helpers.label.user.gender.f'
    #
    def govuk_radio_button(attribute, value, *args)
      options = args.extract_options!.symbolize_keys!
      radio_button_helper.html(attribute, value, options)
    end

    # Usage:
    # Labels of each radio buttons can be either passed as parameters or defined in the locale file.
    # For examples, for the gender of a user, if the radio button values are 'm' and 'f' the labels can be define at:
    # 'helpers.label.user.gender.f'
    #
    # Option 1:
    # <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm']) %>
    # Option 2:
    # <%= form.govuk_collection_radio_buttons(:gender, [{ code: 'f' }, { code: 'm' }], :code) %>
    # Option 3:
    # <%= form.govuk_collection_radio_buttons(:gender, [{ code: 'f', label: 'Female' }, { code: 'm', label: 'Male' }], :code, :label) %>
    #
    # A hint will be displayed if it is defined in the locale file:
    # 'helpers.hint.user.gender'
    #
    # You can pass a title with the :title parameter.
    # e.g., <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm'], title: 'What is your gender?') %>
    #
    # You can pass an error with the :error parameter.
    # e.g., <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm'], error: 'Please select a gender') %>
    #
    # If you wish to specify the size of the heading and/or which header tag to use, pass a hash into title with text and size:
    # And the default for header tag, if no htag is supplied, is h1
    # <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm'], title: { text: 'What is your gender?', size: :m, htag: :h2 } ) %>
    #
    # Use the :inline parameter to have the radio buttons displayed horizontally rather than vertically
    # e.g., <%= form.govuk_collection_radio_buttons(:gender, ['f', 'm'], inline: true) %>
    #
    def govuk_collection_radio_buttons(attribute, collection, *args)
      options = args.extract_options!.symbolize_keys!
      content_tag(:div, class: collection_radio_buttons_classes(attribute, options)) do
        fieldset(attribute, options) do
          classes = ['govuk-radios']
          classes << (options[:inline] ? 'govuk-radios--inline' : 'govuk-!-padding-top-2')
          concat_tags(
            hint_helper.with_error_tags(attribute, options),
            radio_button_collection(attribute, collection, options)
          )
        end
      end
    end

    private

    def hint_helper
      @hint_helper ||= HintTag.new(self)
    end

    def input_helper
      @input_helper ||= InputField.new(self, hint_helper)
    end

    def radio_button_helper
      @radio_button_helper = RadioButton.new(self, hint_helper)
    end

    def radio_button_collection(attribute, collection, options)
      content_tag(:div, class: classes.join(' ')) do
        concat_tags(radio_buttons_input(attribute, collection, options))
      end
    end

    def radio_buttons_input(attribute, collection, options)
      value_attr, label_attr = extract_value_and_label_attributes(args)

      collection.map do |obj|
        value = value_attr ? obj[value_attr] : obj
        label = label_attr ? obj[label_attr] : nil
        input_attributes = options.dig(:input_attributes, value.to_s) || {}
        radio_button_helper.html(attribute, value, options.merge(input_attributes).merge(label: label, collection: true))
      end
    end

    def concat_tags(*tags)
      tags.compact.join.html_safe
    end

    def extract_value_and_label_attributes(args)
      value_attr = args[0].is_a?(Hash) ? nil : args[0]
      label_attr = args[1].is_a?(Hash) ? nil : args[1]
      [value_attr, label_attr]
    end

    def collection_radio_buttons_classes(attribute, options)
      classes = ['govuk-form-group']
      classes << 'govuk-form-group--error' if error?(attribute, options)
      classes.join(' ')
    end

    def fieldset(attribute, options)
      content_tag(:fieldset, class: 'govuk-fieldset', 'aria-describedby': aria_describedby(attribute, options)) do
        legend_tag = options[:title] ? fieldset_legend(options[:title]) : nil
        concat_tags(legend_tag, yield)
      end
    end

    def aria_describedby(attribute, options)
      aria_describedby = []
      aria_describedby << "#{attribute}-hint" if hint_helper.hint?(attribute, options)
      aria_describedby << "#{attribute}-error" if error?(attribute, options)
      return if aria_describedby.empty?

      aria_describedby.join(' ')
    end

    # title param can either be:
    # * a text string, e.g  "My title"
    # * a hash, e.g { text: "My title", size: :m, htag: :h2 }
    #
    def fieldset_legend(title)
      title = text_hash(title)
      size = title.fetch(:size, 'xl')
      htag = title.fetch(:htag, :h1)
      content_tag(:legend, class: "govuk-fieldset__legend govuk-fieldset__legend--#{size}") do
        content_tag(htag, title[:text], class: 'govuk-fieldset__heading')
      end
    end

    def text_hash(text)
      text.is_a?(Hash) ? text : { text: text }
    end

    def error?(attribute, options)
      return true if options[:error]

      attr = options[:field_with_error] || attribute
      object.respond_to?(:errors) &&
        errors.messages.key?(attr) &&
        errors.messages[attr].present?
    end
  end
end
