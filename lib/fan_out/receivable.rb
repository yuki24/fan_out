require 'active_support/concern'

module FanOut::Receivable
  extend ActiveSupport::Concern

  class_methods do
    def has_inbox_for(deliverable_name, join_table: FanOut.inbox_table_name(name, deliverable_name), **options)
      has_and_belongs_to_many deliverable_name, -> { order("#{join_table}.score" => :desc) }, join_table: join_table, **options

      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        # def message_inbox
        #   @message_inbox ||= Inbox.new(messages, "messages", association(:"messages"))
        # end
        def #{deliverable_name.to_s.singularize}_inbox
          @#{deliverable_name}_inbox ||= Inbox.new(#{deliverable_name}, "#{deliverable_name}", association("#{deliverable_name}"))
        end
      RUBY
    end
  end

  class Inbox < SimpleDelegator
    attr_reader :deliverable_name, :association_proxy

    def initialize(obj, deliverable_name, association_proxy)
      super(obj)
      @deliverable_name = deliverable_name
      @association_proxy = association_proxy
    end

    def +(other_inbox)
      if deliverable_class != other_inbox.klass
        raise ArgumentError, "The deriverable class does not match: given #{other_inbox.klass.to_s}, expected #{deliverable_class.to_s}"
      end

      union = +"("
      union << [self.inbox_records, other_inbox.inbox_records].map { |scope| "(#{scope.to_sql})" }.join(" UNION ALL ")
      union << ") #{inbox_name}"

      join_on_expr = __getobj__.joins_values[0].right

      right    = Arel::Attributes::Attribute.new(Arel::Table.new(inbox_name), join_on_expr.expr.right.name)
      equality = Arel::Nodes::Equality.new(join_on_expr.expr.left, right)
      on       = Arel::Nodes::On.new(equality)
      join     = Arel::Nodes::LeadingJoin.new(Arel.sql(union), on)

      deliverable_class.joins(join).order("#{inbox_name}.score" => :desc)
    end

    def inbox_records
      deliverable_class
        .unscoped
        .select("*")
        .from(association_proxy.reflection.options[:join_table].to_s)
        .where(__getobj__.where_clause.ast)
        .order("#{association_proxy.reflection.options[:join_table].to_s}.score" => :desc)
    end

    private

    def inbox_name
      "#{deliverable_name.to_s.singularize}_inbox"
    end

    def deliverable_class
      __getobj__.klass
    end
  end

  private_constant :Inbox
end
