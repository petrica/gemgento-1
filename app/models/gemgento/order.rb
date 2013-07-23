module Gemgento
  class Order < ActiveRecord::Base
    belongs_to  :store
    belongs_to  :user
    belongs_to  :user_group

    belongs_to  :shipping_address, foreign_key: 'shipping_address_id', class_name: 'Address'
    accepts_nested_attributes_for :shipping_address

    belongs_to  :billing_address, foreign_key: 'billing_address_id', class_name: 'Address'
    accepts_nested_attributes_for :billing_address

    has_one     :order_payment
    accepts_nested_attributes_for :order_payment

    has_one     :gift_message
    has_many    :order_items
    has_many    :order_statuses

    def self.index
      if Order.find(:all).size == 0
        API::SOAP::Sales::Order.fetch_all
      end

      Order.find(:all)
    end

    # CART specific functions

    def self.get_cart(order_id = nil)
      if order_id.nil?
        cart = Order.new
        cart.state = 'cart'
        cart.store = Store.first
      else
        cart = Order.find(order_id)
      end

      cart
    end

    def add_item(product, quantity = 1)
      raise 'Order not in cart state' if self.state != 'cart'

      order_item = self.order_items.find_by(product: product)

      if order_item.nil?
       order_item = OrderItem.new
       order_item.product = product
       order_item.qty_ordered = quantity
       order_item.order = self
       order_item.save

       unless self.magento_quote_id.nil?
         API::SOAP::Checkout::Product.add(self, [order_item])
       end
      else
       self.update_item(product, order_item.qty_ordered + quantity.to_i)
      end
    end

    def update_item(product, quantity = 1)
      raise 'Order not in cart state' if self.state != 'cart'

      order_item = self.order_items.find_by(product: product)

      unless order_item.nil?
        order_item.qty_ordered = quantity.to_i
        order_item.save

        unless self.magento_quote_id.nil?
          API::SOAP::Checkout::Product.update(self, [order_item])
        end
      else
        self.add_item(product, quantity)
      end
    end

    def remove_item(product)
      raise 'Order not in cart state' if self.state != 'cart'

      order_item = self.order_items.find_by(product: product)

      unless order_item.nil?
        API::SOAP::Checkout::Product.remove(self, [order_item])
        order_item.destroy
      end
    end

    def push_cart
      raise 'Cart already pushed, creating a new cart' unless self.magento_quote_id.nil?
      API::SOAP::Checkout::Cart.create(self)
      API::SOAP::Checkout::Customer.set(self, self.user)
      API::SOAP::Checkout::Product.add(self, self.order_items)
    end

    def get_totals
      API::SOAP::Checkout::Cart.totals(self)
    end

    # functions related to processing cart into order

    def push_address(address)
      API::SOAP::Checkout::Customer.address(self, address)
    end

    def get_payment_methods
      API::SOAP::Checkout::Payment.list(self)
    end

    def push_payment_method(payment)
      API::SOAP::Checkout::Payment.method(self, payment)
    end

    def push_customer
      API::SOAP::Checkout::Customer.set(self, self.user)
    end

    def get_shipping_methods
      raise 'Order shipping address not set' if self.shipping_address.nil?
      API::SOAP::Checkout::Shipping.list(self)
    end

    def push_shipping_method
      raise 'Shipping method has not been set' if self.shipping_method.nil?
      API::SOAP::Checkout::Shipping.method(self, self.shipping_method)
    end

    def process
      # ensure all essential cart data has been added
      self.push_cart if self.magento_quote_id.nil?
      self.push_customer()
      self.push_address(self.shipping_address)
      self.push_address(self.billing_address)
      self.push_shipping_method
      self.push_payment_method(self.order_payment)
      API::SOAP::Checkout::Cart.order(self)
    end
  end
end