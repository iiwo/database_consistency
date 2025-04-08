# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ImplicitTablesChecker, :postgresql do
  subject(:checker) { described_class.new }

  let(:configuration) { DatabaseConsistency::Configuration.new }

  before do
    allow(configuration).to receive(:checker_enabled?).and_return(true)
  end

  context 'when there is an implicit table with primary key' do
    before do
      define_database do
        create_table :users_projects do |t|
          t.integer :user_id
          t.integer :project_id
        end
      end

      # Mock the models method to return empty array so our table is considered implicit
      allow(DatabaseConsistency::Helper).to receive(:models).and_return([])
    end

    specify do
      report = checker.report_if_enabled?(configuration).first
      expect(report).to have_attributes(
        checker_name: 'ImplicitTablesChecker',
        table_or_model_name: 'users_projects',
        column_or_attribute_name: nil,
        status: :ok,
        error_message: nil,
        error_slug: nil,
        table_name: 'users_projects',
        replica_identity: 'd'
      )
    end
  end

  context 'when there is an implicit table without primary key but with replica identity' do
    before do
      define_database do
        create_table :users_projects, id: false do |t|
          t.integer :user_id
          t.integer :project_id
        end
      end

      # Set replica identity to FULL
      ActiveRecord::Base.connection.execute(
        "ALTER TABLE users_projects REPLICA IDENTITY FULL;"
      )

      # Mock the models method to return empty array so our table is considered implicit
      allow(DatabaseConsistency::Helper).to receive(:models).and_return([])
    end

    specify do
      report = checker.report_if_enabled?(configuration).first
      expect(report).to have_attributes(
        checker_name: 'ImplicitTablesChecker',
        table_or_model_name: 'users_projects',
        column_or_attribute_name: nil,
        status: :ok,
        error_message: nil,
        error_slug: nil,
        table_name: 'users_projects',
        replica_identity: 'f'
      )
    end
  end

  context 'when there is an implicit table without primary key and without replica identity' do
    before do
      define_database do
        create_table :users_projects, id: false do |t|
          t.integer :user_id
          t.integer :project_id
        end
      end

      # Mock the models method to return empty array so our table is considered implicit
      allow(DatabaseConsistency::Helper).to receive(:models).and_return([])
    end

    specify do
      report = checker.report_if_enabled?(configuration).first
      expect(report).to have_attributes(
        checker_name: 'ImplicitTablesChecker',
        table_or_model_name: 'users_projects',
        column_or_attribute_name: nil,
        status: :fail,
        error_message: "Implicit table 'users_projects' has no primary key and no replica identity set, which may cause issues with logical replication",
        error_slug: :missing_pk_or_replica_identity,
        table_name: 'users_projects',
        replica_identity: 'd'
      )
    end
  end
end
