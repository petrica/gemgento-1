module Gemgento
  class SubscribersController < ApplicationController

    respond_to :js, :json, :html

    def new
      @subscriber = Subscriber.new

      respond_with @subscriber
    end

    def create
      @subscriber = Subscriber.create(subscriber_params)

      respond_to do |format|
        if @subscriber.save
          format.html
          format.js { render action: 'create', layout: false }
          format.json { render json: { result: true, subscriber: @subscriber } }
        else
          format.html
          format.js { render action: 'errors', layout: false }
          format.json { render json: { result: false, errors: @subscriber.errors.full_messages } }
        end
      end
    end

    private

    def subscriber_params
      params.require(:subscriber).permit(:first_name, :last_name, :email, :country_id, :city)
    end

  end
end