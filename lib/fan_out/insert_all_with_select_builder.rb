module FanOut
  class InsertAllWithSelectBuilder
    attr_reader :attributes, :select_scope, :model, :connection

    def initialize(model, attributes, select_scope, connection)
      @model = model
      @attributes = attributes
      @select_scope = select_scope
      @connection = connection
    end

    def into
      "INTO #{model.quoted_table_name} (#{columns_list})"
    end

    def values_list
      select_scope.to_sql
    end

    def returning
      nil
    end

    def skip_duplicates?
      true
    end

    def conflict_target
      ''
    end

    private

    def columns_list
      attributes.map(&connection.method(:quote_column_name)).join(", ")
    end
  end
end
