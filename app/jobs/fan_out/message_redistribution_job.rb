class FanOut::MessageRedistributionJob < FanOut::Job
  queue_as :default

  def perform(deliverable, scopes:)
    deliverable.withdraw_deliveries!(scopes: Array.wrap(scopes))
    FanOut::MessageDistributionJob.perform_later(deliverable, scopes: Array.wrap(scopes))
  end
end
