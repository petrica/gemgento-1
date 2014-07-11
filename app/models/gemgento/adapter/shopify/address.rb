module Gemgento::Adapter::Shopify
  class Address

    # Import Shopify address to Gemgento
    #
    # @param address [ShopifyAPI::Address]
    # @param user [Gemgento::User]
    # @param is_default [Boolean]
    def self.import(shopify_address, user)
      if shopify_adapter = Gemgento::Adapter::ShopifyAdapter.find_by_shopify_model(shopify_address)
        address = shopify_adapter.gemgento_model
      else
        address = Gemgento::Address.new
      end

      address.user = user
      address.address1 = shopify_address.address1
      address.address2 = shopify_address.address2
      address.city = shopify_address.city
      address.company = shopify_address.company
      address.country = Gemgento::Country.find_by(iso2_code: shopify_address.country_code)
      address.first_name = shopify_address.first_name
      address.last_name = shopify_address.last_name
      address.telephone = shopify_address.phone
      address.region = Gemgento::Region.find_by(code: shopify_address.province_code)
      address.postcode = shopify_address.zip
      address.is_default_billing = shopify_address.default ? true : false
      address.is_default_shipping = shopify_address.default ? true : false
      address.sync_needed = true
      address.save

      Gemgento::Adapter::ShopifyAdapter.create_association(address, shopify_address) if address.shopify_adapter.nil?
    end

  end
end