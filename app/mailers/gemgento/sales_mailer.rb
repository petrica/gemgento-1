module Gemgento
  class SalesMailer < ActionMailer::Base
    default from: 'sales@gemgento.com'

    def order_email(recipients, from, order_source)
      @order = Gemgento::Magento::OrderAdapter.find(order_source[:increment_id]).import
      @order_source = order_source

      mail(
          to: recipients[:to],
          cc: recipients[:cc],
          bcc: recipients[:bcc],
          from: from,
          subject: order_email_subject
      )
    end

    def invoice_email(recipients, from, order_source, invoice_source)
      @order = Gemgento::Magento::OrderAdapter.find(order_source[:increment_id]).import
      @order_source = order_source
      @invoice_source = invoice_source

      mail(
          to: recipients[:to],
          cc: recipients[:cc],
          bcc: recipients[:bcc],
          from: from,
          subject: invoice_email_subject
      )
    end

    # @param recipients [Hash(Array(String))]
    # @param from [Array(String), String]
    # @param order [Gemgento::Order]
    # @param shipment [Gemgento::Shipment]
    def shipment_email(recipients, from, order, shipment)
      @order = order
      @shipment = shipment

      mail(
          to: recipients[:to],
          cc: recipients[:cc],
          bcc: recipients[:bcc],
          from: from,
          subject: shipment_email_subject
      )
    end

    def credit_memo_email(recipients, from, order_source, credit_memo_source)
      @order = Gemgento::Magento::OrderAdapter.find(order_source[:increment_id]).import
      @order_source = order_source
      @credit_memo_source = credit_memo_source

      mail(
          to: recipients[:to],
          cc: recipients[:cc],
          bcc: recipients[:bcc],
          from: from,
          subject: credit_memo_email_subject
      )
    end

    def order_email_subject
      "Confirmation for Order #{@order.increment_id}"
    end

    def invoice_email_subject
      "Invoice for Order #{@order.increment_id}"
    end

    def shipment_email_subject
      "Shipment for Order #{@order.increment_id}"
    end

    def credit_memo_email_subject
      "Credit Memo for Order #{@order.increment_id}"
    end

  end
end