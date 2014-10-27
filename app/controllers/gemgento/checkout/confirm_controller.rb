module Gemgento
  class Checkout::ConfirmController < CheckoutController
    respond_to :json, :html

    def show
      @shipping_address = current_order.shipping_address
      @billing_address = current_order.billing_address
      @payment = current_order.order_payment

      @shipping_method = get_magento_shipping_method

      respond_to do |format|
        format.html
        format.json { render json: { order: current_order, shipping_method: @shipping_method, totals: current_order.totals } }
      end
    end

    def update
      current_order.enforce_cart_data
      @order = current_order
      @order.order_payment.update(session[:payment_data])

      respond_to do |format|
        if current_order.process(request.remote_ip)
          session.delete :payment_data

          format.html do
            cookies[:order] = @order.id
            redirect_to checkout_thank_you_path
          end

          format.json do
            @order.reload
            render json: { result: true, order: @order }
          end
        else
          flash[:error] = 'There was a problem processing your order.  Please review order details and try again.'

          format.html { redirect_to checkout_confirm_path }
          format.json do
            render json: {
                result: false,
                errors: 'There was a problem processing your order.  Please review order details and try again.'
            }
          end
        end
      end

    end

  end
end