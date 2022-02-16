module FanOut::UnionScope
  def union(*sub_queries)
    UnionValue.new(sub_queries, type: 'UNION')
  end

  def union_all(*sub_queries)
    UnionValue.new(sub_queries, type: 'UNION ALL')
  end

  class UnionValue
    attr_reader :sub_queries, :type

    def initialize(sub_queries, type:)
      @sub_queries = sub_queries
      @type = type
    end

    def as(alias_name)
      "((#{sub_queries.map(&:to_sql).join(") #{type} (")})) #{alias_name}"
    end
  end

  private_constant :UnionValue
end
