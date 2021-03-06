module Gemgento
  module API
    module SOAP
      module Checkout
        class Cart

          # Create a magento quote.
          #
          # @param [Order] cart
          # @return [MagentoResponse]
          def self.create(cart)
            message = {
                store_id: cart.store.magento_id,
                gemgento_id: cart.id
            }
            MagentoApi.create_call(:shopping_cart_create, message)
          end

          # Process magento quote.
          #
          # @param [Order] quote
          # @param [Gemgento::Payment] payment
          # @param [String] remote_ip
          # @return [MagentoResponse]
          def self.order(quote, payment, remote_ip)
            message = {
                quote_id: quote.magento_id,
                store_id: quote.store.magento_id,
                remote_ip: remote_ip
            }

            if payment
              message[:payment_data] = {
                  'po_number' => payment.po_number,
                  method: payment.method,
                  'cc_cid' => payment.cc_cid,
                  'cc_owner' => payment.cc_owner,
                  'cc_number' => payment.cc_number,
                  'cc_type' => payment.cc_type,
                  'cc_exp_year' => payment.cc_exp_year,
                  'cc_exp_month' => payment.cc_exp_month,
                  'additional_information' => API::SOAP::Checkout::Payment.compose_additional_information(payment)
              }

              message[:send_email] = !payment.is_redirecting_payment_method? # don't send emails for payment methods that require a redirect.
            end

            MagentoApi.create_call(:shopping_cart_order, message)
          end

          def self.info(quote_id, store_id = nil)
            message = { quote_id: quote_id }
            message[:store_id] = store_id unless store_id.nil?
            MagentoApi.create_call(:shopping_cart_info, message)
          end

          # Mage a Magento API call to get quote totals.
          #
          # @param quote [Gemgento::Quote]
          # @return [Gemgento::MagentoResponse]
          def self.totals(quote)
            message = {
                quote_id: quote.magento_id,
                store_id: quote.store.magento_id
            }
            MagentoApi.create_call(:shopping_cart_totals, message)
          end

          def self.license(cart)
            message = {
                quote_id: cart.magento_quote_id,
                store_id: cart.store.magento_id
            }
            response = MagentoApi.create_call(:shopping_cart_license, message)

            if response.success?
              response.body[:result][:item]
            end
          end

        end
      end
    end
  end
end