module Gemgento
  class User::AddressesController < User::BaseController

    def index
      @new_shipping_address = Address.new
      @default_shipping_address = current_user.default_shipping_address

      @new_billing_address = Address.new
      @default_billing_address = current_user.default_billing_address

      @address_book = current_user.address_book

      respond_to do |format|
        format.html
        format.json { render json: current_user.address_book }
      end
    end

    def show
      @address = current_user.address_book.find(params[:id])
      respond_with @address
    end

    def new
      @address = Gemgento::Address.new
    end

    def edit
      @address = current_user.address_book.find(params[:id])
      respond_with @address
    end

    def create
      @address = Address.new(address_params)
      @address.user = current_user
      @address.sync_needed = true

      respond_to do |format|
        if @address.save
          flash[:notice] = 'The new address was created successfully.'
          format.html { redirect_to action: 'index' }
          format.js { render '/gemgento/users/addresses/success' }
          format.json { render json: { result: true, address: @address } }
        else
          format.html { render 'new' }
          format.js { render '/gemgento/users/addresses/errors' }
          format.json { render json: { result: false, errors: @address.errors.full_messages } }
        end
      end
    end

    def update
      @address = current_user.address_book.find(params[:id])
      @address.sync_needed = true

      respond_to do |format|
        if @address.update_attributes(address_params)
          flash[:notice] = 'The new address was updated successfully.'
          format.html { redirect_to action: 'index' }
          format.js { render '/gemgento/users/addresses/success' }
          format.json { render json: { result: true, address: @address } }
        else
          format.html { render 'edit' }
          format.js { render '/gemgento/users/addresses/errors' }
          format.json { render json: { result: false, errors: @address.errors.full_messages } }
        end
      end
    end

    def destroy
      current_user.address_book.find(params[:id]).destroy
      flash[:notice] = 'The address was removed.'
      respond_to do |format|
        format.html { redirect_to action: 'index' }
        format.json { render json: { result: true } }
      end
    end

    private

    def address_params
      params.require(:address).permit(
          :first_name, :last_name, :address1, :address2, :address3, :country_id, :city, :region_id, :postcode,
          :telephone, :is_default_shipping, :is_default_billing, :address_type
      )
    end
  end
end