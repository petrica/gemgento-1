module Gemgento
  class CartController < Gemgento::ApplicationController
    ssl_allowed

    respond_to :js, :json, :html

    def show
      @cart = current_order

      respond_with @cart
    end

    def create
      @errors = []

      # save the order and mark is as the current cart
      current_order.save
      session[:cart] = current_order.id

      add_item

      respond_to do |format|
        format.html { render 'gemgento/checkout/shopping_bag' }
        format.js { render '/gemgento/order/add_item', :layout => false }
      end
    end

    def update
      raise 'Missing action parameter' if params[:activity].nil?
      @errors = []

      if current_order.id.nil?
        current_order.user = current_user
        current_order.save
        session[:cart] = current_order.id
      end

      case params[:activity]
        when 'add_item'
          @product = add_item
          current_order.reload

          respond_to do |format|
            unless @product
              format.html {
                begin
                  redirect_to :back
                rescue
                  redirect_to root_path
                end
              }
              format.js { render '/gemgento/order/no_inventory', layout: false }
              format.json {
                render json: {
                    result: false,
                    errors: flash[:error],
                    order: current_order
                }
                flash[:error] = false
              }
            else
              format.html { redirect_to action: 'show' }
              format.js { render '/gemgento/order/add_item', layout: false }
              format.json { render json: { result: true, order: current_order } }
            end
          end
        when 'update_item'
          @product = update_item
          current_order.reload

          respond_to do |format|
            unless @product
              format.html {
                begin
                  redirect_to :back
                rescue
                  redirect_to root_path
                end
              }
              format.js { render '/gemgento/order/no_inventory', layout: false }
              format.json {
                render json: {
                  result: false,
                  errors: flash[:error],
                  order: current_order
                }
                flash[:error] = false
              }
            else
              format.html { redirect_to action: 'show' }
              format.js { render '/gemgento/order/update_item', layout: false }
              format.json { render json: {result: true, order: current_order} }
            end
          end
        when 'remove_item'
          remove_item
          current_order.reload

          respond_to do |format|
            format.html { redirect_to action: 'show' }
            format.js { render '/gemgento/order/remove_item', layout: false }
            format.json { render json: {result: true, order: current_order} }
          end
        else
          raise "Unknown action - #{params[:activity]}"
          render nothing: true
      end
    end

    def mini_bag
      render partial: 'shared/mini_bag'
    end

    private

    def add_item
      # validate the parameters
      raise 'Product ID not specified' if params[:product_id].nil?
      raise 'Quantity not specified' if params[:quantity].nil?
      raise 'Quantity must be greater than 0' if params[:quantity].to_i <= 0

      product = Gemgento::Product.find(params[:product_id])
      raise 'Product does not exist' if product.nil?

      order_item = current_order.order_items.find_by(product: product)

      if order_item.nil?
        if product.in_stock? params[:quantity], current_store
          # add the item to the order
          result = current_order.add_item(product, params[:quantity], params[:options], params[:background_worker])
          if result == true
            return product
          else
            flash[:error] = result
            return false
          end
        else
          return false
        end
      else
        params[:quantity] = params[:quantity].to_f + order_item.qty_ordered
        return update_item
      end
    end

    def update_item
      raise 'Product not specified' if params[:product_id].nil?
      raise 'Quantity not specified' if params[:quantity].nil?
      raise 'Quantity must be greater than 0' if params[:quantity].to_i <= 0

      product = Gemgento::Product.find(params[:product_id])
      raise 'Product does not exist' if product.nil?

      if product.in_stock? params[:quantity], current_store
        # update the item
        result = current_order.update_item(product, params[:quantity], params[:options], params[:background_worker])
        if result == true
          return product
        else
          flash[:error] = result
          return false
        end
      else
        return false
      end
    end

    def remove_item
      raise 'Product not specified' if params[:product_id].nil?

      product = Gemgento::Product.find(params[:product_id])
      raise 'Product does not exist' if product.nil?

      current_order.remove_item(product)
    end

  end
end