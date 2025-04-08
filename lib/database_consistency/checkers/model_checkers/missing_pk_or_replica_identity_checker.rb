# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks that a table has a primary key or a replica identity set
    # This is important for logical replication in PostgreSQL
    class MissingPkOrReplicaIdentityChecker < ModelChecker
      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :table_name,
        :replica_identity
      )

      private

      def preconditions
        !model.abstract_class? && Helper.postgresql?
      end

      def check
        if model.table_exists?
          check_table_pk_or_replica_identity
        else
          report_template(:ok)
        end
      end

      def check_table_pk_or_replica_identity
        if has_primary_key?
          report_template(:ok)
        elsif has_replica_identity?
          report_template(:ok)
        else
          report_template(:fail, error_slug: :missing_pk_or_replica_identity)
        end
      end

      def has_primary_key?
        !model.primary_key.nil?
      end

      def has_replica_identity?
        replica_identity = fetch_replica_identity(model.table_name)
        replica_identity != 'd' # 'd' is default which relies on primary key
      end

      def fetch_replica_identity(table_name)
        result = model.connection.execute(<<~SQL)
          SELECT relreplident
          FROM pg_class
          WHERE oid = '#{table_name}'::regclass;
        SQL
        result.first['relreplident']
      end

      def report_template(status, error_slug: nil)
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: error_message(status, error_slug),
          table_name: model.table_name,
          replica_identity: fetch_replica_identity(model.table_name),
          **report_attributes
        )
      end

      def error_message(status, error_slug)
        return nil if status == :ok

        case error_slug
        when :missing_pk_or_replica_identity
          "Table '#{model.table_name}' has no primary key and no replica identity set, which may cause issues with logical replication"
        end
      end
    end
  end
end
