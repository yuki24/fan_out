class FanOut::MessageDeletionJob < FanOut::Job
  queue_as :default

  def perform(deliverable, target_scope)
    deliverable.withdraw_deliveries!(scopes: [target_scope])
  end
end
