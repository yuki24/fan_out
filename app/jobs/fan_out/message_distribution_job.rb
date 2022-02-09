class FanOut::MessageDistributionJob < FanOut::Job
  queue_as :default

  def perform(deliverable, scopes:)
    deliverable.fan_out!(scopes: Array.wrap(scopes))
  end
end
