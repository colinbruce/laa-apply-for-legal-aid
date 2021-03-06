module Reports
  module BankTransactions
    class BankTransactionReportCreator < BaseReportCreator
      # generate_local_csv is used for manual testing in the console
      #    rc = Reports::BankTransactions::BankTransactionReportCreator.new(laa)
      #    rc.call(local_csv: true)
      #
      def call(local_csv: false)
        local_csv ? generate_csv_locally : generate_attachment
      end

      private

      def generate_csv_locally
        File.open(Rails.root.join('tmp', 'bank_transactions.csv'), 'wb') do |fp|
          fp.puts generate_csv
        end
      end

      def generate_attachment
        return if legal_aid_application.bank_transaction_report

        attachment = legal_aid_application.attachments.create!(attachment_type: 'bank_transaction_report',
                                                               attachment_name: 'bank_transaction_report.csv')

        attachment.document.attach(
          io: StringIO.new(generate_report),
          filename: 'bank_transaction_report.csv',
          content_type: 'text/csv'
        )
      end

      def generate_report
        ensure_case_ccms_reference_exists
        generate_csv
      end

      def generate_csv
        transactions = BankTransactionSorter.call(legal_aid_application)
        csv_string = CSV.generate do |csv|
          csv << BankTransactionPresenter.headers
          transactions.each do |transaction|
            remarks = transaction_remarks_for[transaction.id]&.reasons.to_a
            csv << BankTransactionPresenter.present!(transaction, remarks)
          end
        end
        csv_string
      end

      def transaction_remarks_for
        @transaction_remarks_for ||= legal_aid_application.cfe_result.remarks.review_transactions.transactions
      end
    end
  end
end
