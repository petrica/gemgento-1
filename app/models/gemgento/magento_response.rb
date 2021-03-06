module Gemgento

  # @author Gemgento LLC
  class MagentoResponse < ActiveRecord::Base
    serialize :request, Hash
    serialize :body, Hash

    attr_accessor :body_overflow
  end
end