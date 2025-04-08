# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      # The class to write missing primary key or replica identity error
      class MissingPkOrReplicaIdentity < Base
        def message
          "Table '#{report.table_name}' has no primary key and no replica identity set, which may cause issues with logical replication"
        end

        def hint
          "Add a primary key to the table or set a replica identity using 'ALTER TABLE #{report.table_name} REPLICA IDENTITY FULL;'"
        end
      end
    end
  end
end
