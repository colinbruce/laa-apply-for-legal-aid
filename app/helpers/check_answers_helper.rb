module CheckAnswersHelper
  # Creates one dictionary list item - so needs to be used within a `govuk-summary-list` `dl`:
  #     <dl class="govuk-summary-list govuk-!-margin-bottom-9">
  #       <%= check_answer_link ..... %>
  #     </dl>
  def check_answer_link(question:, answer:, name:, url: nil, read_only: false, align_right: false, no_border: false) # rubocop:disable Metrics/ParameterLists
    render(
      'shared/check_answers/item',
      name: name,
      url: url,
      question: question,
      answer: answer,
      read_only: url.nil? ? true : read_only,
      no_border: no_border,
      align_right: align_right
    )
  end

  def check_answer_no_link(question:, answer:, name:, no_border: false)
    render(
      'shared/check_answers/no_link_item',
      name: name,
      question: question,
      answer: answer,
      no_border: no_border
    )
  end

  # Creates both the outer `div` and the inner list items
  def check_answer_one_change_link(url:, question:, answer_hash:, name:, read_only: false)
    render(
      'shared/check_answers/one_link_section',
      name: name,
      url: url,
      question: question,
      answer_hash: answer_hash,
      read_only: read_only
    )
  end

  def check_answer_change_link(name:, url:, question:, read_only: false)
    render(
      'shared/check_answers/only_link_section',
      name: name,
      url: url,
      question: question,
      read_only: read_only
    )
  end

  def check_long_questions_single_change_link(url:, question:, answer_hash:, name:, read_only: false)
    render(
      'shared/check_answers/one_change_link_long_answers_section',
      url: url,
      name: name,
      question: question,
      answer_hash: answer_hash,
      read_only: read_only
    )
  end

  def check_long_question_no_link(question:, answer:, name:, no_border: false)
    render(
      'shared/check_answers/no_link_long_item',
      name: name,
      question: question,
      answer: answer,
      no_border: no_border
    )
  end

  def number_to_currency_or_na(number)
    number.to_d == 999_999_999_999.0.to_d ? 'N/a' : gds_number_to_currency(number)
  end
end
