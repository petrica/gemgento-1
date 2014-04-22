module Gemgento
  class Magento::AddressesController < MagentoController

    def update
      data = params[:data]
      user = Gemgento::User.find_by(magento_id: data[:customer_id])

      unless user.nil?
        @address = Gemgento::Address.find_or_initialize_by(user_address_id: data[:entity_id])
        @address.user = user
        @address.city = data[:city]
        @address.company = data[:company]
        @address.country = Country.where(magento_id: data[:country_id]).first
        @address.fax = data[:fax]
        @address.first_name = data[:firstname]
        @address.middle_name = data[:middlename]
        @address.last_name = data[:lastname]
        @address.postcode = data[:postcode]
        @address.prefix = data[:prefix]
        @address.region_name = data[:region]
        @address.region = Region.where(magento_id: data[:region_id]).first
        @address.street = data[:street]
        @address.suffix = data[:suffix]
        @address.telephone = data[:telephone]
        @address.is_default_billing = data[:is_default_billing]
        @address.is_default_shipping = data[:is_default_shipping]
        @address.sync_needed = false
        @address.save
      end

      render nothing: true
    end

    def destroy
      Gemgento::Address.skip_callback(:destroy, :before, :destroy_magento)

      @address = Gemgento::Address.find_by(user_address_id: params[:id])
      @address.destroy unless @address.nil?

      Gemgento::Address.set_callback(:destroy, :before, :destroy_magento)

      render nothing: true
    end

  end
end