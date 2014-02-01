module Gemgento
  class Users::AddressesController < Users::UsersBaseController

    def index
      @new_shipping_address = Address.new
      @default_shipping_address = current_user.addresses.where(address_type: 'shipping', is_default: true).first
      @shipping_addresses = current_user.addresses.where(address_type: 'shipping', is_default: false)

      @new_billing_address = Address.new
      @default_billing_address = current_user.addresses.where(address_type: 'billing', is_default: true).first
      @billing_addresses = current_user.addresses.where(address_type: 'billing', is_default: false)

      respond_to do |format|
        format.html
        format.json do
          render json: current_user.addresses
        end
      end
    end

    def show

    end

    def create
      @address = Address.new(address_params)
      @address.user = current_user

      respond_to do |format|
        if @address.save
          format.html { redirect_to '/users/addresses', notice: 'The new address was created successfully.' }
          format.js { render '/gemgento/users/addresses/success' }
          format.json { render json: { result: true, address: @address } }
        else
          format.html { redirect_to '/users/addresses', error: @address.errors.empty? ? 'Error' : @address.errors.full_messages }
          format.js { render '/gemgento/users/addresses/errors' }
          format.json { render json: { result: false, errors: @address.errors.full_messages } }
        end
      end
    end

    def update
      @address = Address.where(params[:id]).first

      respond_to do |format|
        if @address.update_attributes(address_params)
          format.html { redirect_to '/users/addresses', notice: 'The new address was created successfully.' }
          format.js { render '/gemgento/users/addresses/success' }
          format.json { render json: { result: true, address: @address } }
        else
          format.html { redirect_to '/users/addresses', error: @address.errors.empty? ? 'Error' : @address.errors.full_messages }
          format.js { render '/gemgento/users/addresses/errors' }
          format.json { render json: { result: false, errors: @address.errors.full_messages } }
        end
      end
    end

    private

    def address_params
      params.require(:address).permit(:first_name, :last_name, :address1, :address2, :address3, :country_id, :city, :region_id, :postcode, :telephone)
    end
  end
end