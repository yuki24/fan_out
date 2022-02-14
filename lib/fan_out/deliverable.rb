require 'active_support/concern'

require_relative 'message_courier'
require_relative 'insert_all_with_select_builder'

module FanOut
  module Deliverable
    extend ActiveSupport::Concern

    included do
      after_commit :dispatch_message_distribution, on: :create
      after_commit :dispatch_message_redistribution, on: :update
    end

    class_methods do
      def delivered_to(receivable_name, score: nil, deliver_if: nil, redeliver_if: nil, withdraw_if: nil, **options, &block)
        self.message_couriers[receivable_name] = MessageCourier.new(block, score, deliver_if, redeliver_if, withdraw_if)

        table_name     = FanOut.inbox_table_name(receivable_name, name)
        model_name     = FanOut.inbox_model_name(receivable_name, name)
        ancestor_class = defined?(ApplicationRecord) ? ApplicationRecord : ActiveRecord::Base
        inbox_class    = Class.new(ancestor_class) { self.table_name = table_name.to_s }

        has_many table_name, dependent: :delete_all, class_name: "FanOut::#{model_name}", **options
        ::FanOut.const_set(model_name, inbox_class)
      end

      def execute_fan_out_inserts(receivables, inbox_class, attributes)
        InsertAllWithSelectBuilder
          .new(inbox_class, attributes, receivables, connection)
          .then { connection.build_insert_sql(_1) }
          .then { connection.execute(_1) }
      end

      def message_couriers
        @__message_couriers__ ||= {}
      end
    end

    def fan_out!(scopes: self.class.message_couriers.keys)
      self.class.message_couriers.slice(*scopes).each do |scope, message_courier|
        association = association(FanOut.inbox_table_name(scope, self.class.name))
        inbox_class = association.klass
        receivables = message_courier.invoke_method_or_block(self, message_courier.delivery_method)
        score       = message_courier.invoke_method_or_block(self, message_courier.scorer)

        attributes = [
          association.reflection.foreign_key,
          "#{scope.to_s.singularize.underscore}_id",
          score.nil? ? nil : "score",
        ].compact

        if receivables.respond_to?(:to_sql)
          target_model = scope.to_s.classify.constantize

          attribute_values = [
            self.class.connection.quote(id),                                        # deliverable_id,
            "#{target_model.quoted_table_name}.#{target_model.quoted_primary_key}", # receivable_id,
            score                                                                   # score
          ].compact.join(", ")

          self.class.execute_fan_out_inserts(receivables.select(attribute_values), inbox_class, attributes)
        else
          messages_to_deliver = receivables.map do |receivable|
            attributes.zip([id, receivable.id, score]).to_h
          end

          inbox_class.insert_all(messages_to_deliver)
        end
      end
    end

    def withdraw_deliveries!(scopes: self.class.message_couriers.keys)
      scopes.each do |scope|
        association(FanOut.inbox_table_name(scope, self.class.name)).delete_all
      end
    end

    private

    def dispatch_message_distribution
      self.class.message_couriers.each do |scope, message_courier|
        if message_courier.invoke_method_or_block(self, message_courier.deliver_if)
          ::FanOut::MessageDistributionJob.perform_later(self, scopes: scope)
        end
      end
    end

    def dispatch_message_redistribution
      self.class.message_couriers.each do |scope, message_courier|
        if message_courier.invoke_method_or_block(self, message_courier.withdraw_if)
          ::FanOut::MessageDeletionJob.perform_later(self, scopes: scope)
        elsif message_courier.invoke_method_or_block(self, message_courier.redeliver_if)
          ::FanOut::MessageRedistributionJob.perform_later(self, scopes: scope)
        elsif message_courier.invoke_method_or_block(self, message_courier.deliver_if)
          ::FanOut::MessageDistributionJob.perform_later(self, scopes: scope)
        end
      end
    end
  end
end
