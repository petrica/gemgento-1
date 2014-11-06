module Gemgento
  class Checkout::ConfirmController < CheckoutController
    respond_to :json, :html

    def show
      @shipping_method = get_magento_shipping_method

      respond_to do |format|
        format.html
        format.json { render json: { order: @quote, shipping_method: @shipping_method, totals: @quote.totals } }
      end
    end

    def update
      @quote.payment.update(session[:payment_data])

      respond_to do |format|
        if @quote.convert(request.remote_ip)
          session.delete :payment_data
          session[:order] = @quote.order.id

          if !@quote.payment.method.include?('paypal')
            format.html { redirect_to checkout_thank_you_path }
            format.json { render json: { result: true, order: @quote.order } }
          else
            format.html { redirect_to paypal_redirect_url }
            format.json { render json: { result: true, paypal_redirect_url: paypal_redirect_url } }
          end
        else
          @shipping_method = get_magento_shipping_method
          format.html { render 'show' }
          format.json { render json: { result: false, errors: @quote.errors.full_messages }, status: 422 }
        end
      end

    end

    private

    def paypal_redirect_url
      "#{Gemgento::Config[:magento][:url]}/paypal/standard/redirect?quote_id=#{@quote.magento_id}&store_id=#{@quote.store.magento_id}"
    end

  end
end