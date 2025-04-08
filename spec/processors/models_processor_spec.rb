# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors::ModelsProcessor do
  subject(:processor) { described_class.new }

  describe '.checkers' do
    it 'includes MissingTableChecker' do
      expect(described_class.checkers).to include(DatabaseConsistency::Checkers::MissingTableChecker)
    end

    it 'includes MissingPkOrReplicaIdentityChecker' do
      expect(described_class.checkers).to include(DatabaseConsistency::Checkers::MissingPkOrReplicaIdentityChecker)
    end
  end
end
