# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process implicit tables
    class ImplicitTablesProcessor < BaseProcessor
      private

      def check
        enabled_checkers.flat_map do |checker_class|
          DebugContext.with(checker: checker_class) do
            checker = checker_class.new
            checker.report_if_enabled?(configuration)
          end
        end.compact
      end
    end
  end
end
