module Providers
  class CheckMeritsAnswersController < ProviderBaseController
    def show
      legal_aid_application.create_respondent! unless legal_aid_application.respondent
      legal_aid_application.check_merits_answers! unless legal_aid_application.checking_merits_answers?
    end

    def continue
      #legal_aid_application.checked_merits_answers! unless draft_selected? || legal_aid_application.checked_merits_answers?
      #continue_or_draft
      unless draft_selected?
        legal_aid_application.generate_reports! if legal_aid_application.may_generate_reports?
        merits_assessment.submit!
      end
      continue_or_draft
    end

    def reset
      legal_aid_application.reset!
      redirect_to back_path
    end

    private

    def merits_assessment
      @merits_assessment ||= legal_aid_application.merits_assessment || legal_aid_application.build_merits_assessment
    end
  end
end
