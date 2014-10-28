module Gemgento
  module API
    module SOAP
      module Checkout
        class Coupon

          def self.add(cart, coupon_code)
            message = {
                quote_id: cart.magento_quote_id,
                coupon_code: coupon_code,
                store_id: cart.store.magento_id
            }
            Magento.create_call(:shopping_cart_coupon_add, message)
          end

          def self.remove(cart)
            message = {
                quote_id: cart.magento_quote_id,
                store_id: cart.store.magento_id
            }
            Magento.create_call(:shopping_cart_coupon_remove, message)
          end

        end
      end
    end
  end
end