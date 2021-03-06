module Gemgento
  class User::WishlistItemsController < User::BaseController
    prepend_before_action :set_return_to

    before_action :authenticate_user!

    def index
      @wishlist_items = current_user.wishlist_items
      respond_with @wishlist_items
    end

    def create
      @wishlist_item = current_user.wishlist_items.new(wishlist_item_params)

      respond_to do |format|
        if @wishlist_item.save
          format.html { redirect_to user_wishlist_items_path, notice: "Item sucessfully added to wishlist." }
          format.json { render json: { result: true, wishlist_item: @wishlist_item } }
        else
          format.html { redirect_to user_wishlist_items_path }
          format.json { render json: { result: false, errors: @wishlist_item.errors.full_messages } }
        end
      end
    end

    def destroy
      @wishlist_item = current_user.wishlist_items.find(params[:id])

      respond_to do |format|
        if @wishlist_item.destroy
          format.html { redirect_to user_wishlist_items_path , notice: "Wishlist item removed." }
          format.json { render json: { result: true } }
        else
          format.html { render user_wishlist_items_path, alert: 'Unable to remove item from wishlist' }
          format.json { render json: { result: false, errors: @wishlist_item.errors.full_messages } }
        end
      end
    end

    private

    def set_return_to
      if user_signed_in?
        session.delete(:return_to)
      elsif params[:wishlist_item]
        return_params = { wishlist_item: params[:wishlist_item] }.to_query
        session[:return_to] = "#{request.fullpath}/add?#{return_params}"
      end
    end

    def wishlist_item_params
      params.require(:wishlist_item).permit(:product_id)
    end
  end
end
