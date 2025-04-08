# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks implicit tables (like those created by has_and_belongs_to_many)
    # for missing primary keys or replica identities
    class ImplicitTablesChecker < BaseChecker
      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :table_name,
        :replica_identity
      )

      def initialize
        super
      end

      def report_if_enabled?(configuration)
        return nil unless Helper.postgresql?
        return nil unless configuration.checker_enabled?(self.class)

        check_implicit_tables
      end

      private

      def check_implicit_tables
        implicit_tables.map do |table_name|
          if has_primary_key?(table_name)
            report_template(:ok, table_name)
          elsif has_replica_identity?(table_name)
            report_template(:ok, table_name)
          else
            report_template(:fail, table_name, error_slug: :missing_pk_or_replica_identity)
          end
        end
      end

      def implicit_tables
        # Get all tables that might be from has_and_belongs_to_many
        # These typically have names like 'table1_table2' and don't have model classes
        all_tables = ActiveRecord::Base.connection.tables
        model_tables = Helper.models(Configuration.new).map(&:table_name)
        
        # Tables that exist in the database but don't have corresponding models
        implicit_tables = all_tables - model_tables
        
        # Filter out system tables and other non-HABTM tables
        implicit_tables.reject do |table|
          table.start_with?('pg_', 'sql_', 'information_schema') ||
          !table.include?('_')
        end
      end

      def has_primary_key?(table_name)
        result = ActiveRecord::Base.connection.execute(<<~SQL)
          SELECT COUNT(*) > 0 AS has_pk
          FROM information_schema.table_constraints
          WHERE table_name = '#{table_name}'
          AND constraint_type = 'PRIMARY KEY';
        SQL
        result.first['has_pk']
      end

      def has_replica_identity?(table_name)
        replica_identity = fetch_replica_identity(table_name)
        replica_identity != 'd' # 'd' is default which relies on primary key
      end

      def fetch_replica_identity(table_name)
        result = ActiveRecord::Base.connection.execute(<<~SQL)
          SELECT relreplident
          FROM pg_class
          WHERE oid = '#{table_name}'::regclass;
        SQL
        result.first['relreplident']
      end

      def report_template(status, table_name, error_slug: nil)
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: error_message(status, error_slug, table_name),
          table_name: table_name,
          replica_identity: fetch_replica_identity(table_name),
          checker_name: self.class.name.demodulize,
          table_or_model_name: table_name,
          column_or_attribute_name: nil
        )
      end

      def error_message(status, error_slug, table_name)
        return nil if status == :ok

        case error_slug
        when :missing_pk_or_replica_identity
          "Implicit table '#{table_name}' has no primary key and no replica identity set, which may cause issues with logical replication"
        end
      end
    end
  end
end
