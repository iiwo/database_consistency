# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors::ImplicitTablesProcessor do
  subject(:processor) { described_class.new }

  describe '.checkers' do
    it 'includes ImplicitTablesChecker' do
      expect(described_class.checkers).to include(DatabaseConsistency::Checkers::ImplicitTablesChecker)
    end
  end
end
