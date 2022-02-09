module FanOut
  class MessageCourier
    attr_reader :delivery_method, :scorer, :deliver_if, :redeliver_if, :withdraw_if

    def initialize(delivery_method, scorer, deliver_if, redeliver_if, withdraw_if)
      @delivery_method = delivery_method
      @scorer = scorer || -> {}
      @deliver_if = deliver_if || :previously_new_record?
      @redeliver_if = redeliver_if || -> { false }
      @withdraw_if = withdraw_if || :destroyed?
    end

    def invoke_method_or_block(object, symbol_or_block)
      case symbol_or_block
      when Symbol
        object.send(symbol_or_block)
      else
        object.instance_exec(&symbol_or_block)
      end
    end
  end
end
