require 'active_support/concern'

module FanOut::Receivable
  extend ActiveSupport::Concern

  class_methods do
    def has_inbox_for(deliverable_name, **options)
      table_name = FanOut.inbox_table_name(name, deliverable_name)

      has_and_belongs_to_many deliverable_name, -> { order("#{table_name}.score" => :desc) }, join_table: table_name, **options

      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{deliverable_name.to_s.singularize}_inbox # def message_inbox
          #{deliverable_name}                          #   messages
        end                                            # end
      RUBY
    end
  end
end
