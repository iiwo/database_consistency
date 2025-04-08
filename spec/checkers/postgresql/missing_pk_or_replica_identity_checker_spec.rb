# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingPkOrReplicaIdentityChecker, :postgresql do
  subject(:checker) { described_class.new(model) }

  let(:model) { klass }

  context 'when table has a primary key' do
    let(:klass) { define_class }

    before do
      define_database do
        create_table :entities do |t|
          t.string :name
        end
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingPkOrReplicaIdentityChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: nil,
        status: :ok,
        error_message: nil,
        error_slug: nil,
        table_name: 'entities',
        replica_identity: 'd'
      )
    end
  end

  context 'when table has no primary key but has replica identity set' do
    let(:klass) { define_class }

    before do
      define_database do
        create_table :entities, id: false do |t|
          t.string :name
        end
      end

      # Set replica identity to FULL
      ActiveRecord::Base.connection.execute(
        "ALTER TABLE entities REPLICA IDENTITY FULL;"
      )
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingPkOrReplicaIdentityChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: nil,
        status: :ok,
        error_message: nil,
        error_slug: nil,
        table_name: 'entities',
        replica_identity: 'f'
      )
    end
  end

  context 'when table has no primary key and no replica identity set' do
    let(:klass) { define_class }

    before do
      define_database do
        create_table :entities, id: false do |t|
          t.string :name
        end
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingPkOrReplicaIdentityChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: nil,
        status: :fail,
        error_message: "Table 'entities' has no primary key and no replica identity set, which may cause issues with logical replication",
        error_slug: :missing_pk_or_replica_identity,
        table_name: 'entities',
        replica_identity: 'd'
      )
    end
  end
end
