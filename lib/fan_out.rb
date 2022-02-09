# frozen_string_literal: true

require_relative "fan_out/version"

require_relative "fan_out/deliverable"
require_relative "fan_out/receivable"
require_relative "fan_out/engine" if defined?(::Rails::Railtie)

module FanOut
  class Error < StandardError; end

  def self.inbox_table_name(receivable_name, deliverable_name)
    :"fan_out_#{receivable_name.to_s.singularize.underscore}_#{deliverable_name.to_s.singularize.underscore}_inboxes"
  end

  def self.inbox_model_name(receivable_name, deliverable_name)
    :"#{receivable_name.to_s.classify}#{deliverable_name.to_s.classify}Inbox"
  end
end
