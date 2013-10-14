module Gemgento
  class ProductsController < BaseController

    def index
      @products = Product.index
    end

    def show
      if (params[:id])
        @product = Product.find(params[:id])
      else
        @product = Product.active.where(
            gemgento_product_attributes: {code: 'url_key'},
            gemgento_product_attribute_values: {value: params[:url_key]},
        ).first include: :simple_products

        @product.product_attribute_values.reload
      end

      respond_to do |format|
        format.js {
          if @product.magento_type == 'configurable'

            @ps = []
            p = @product; first_simple = p.simple_products.active.first
            @ps << {id: p.id, name: p.attribute_value('name'), description: first_simple.attribute_value('description'), price: first_simple.attribute_value('price')}
            @product.simple_products.active.each do |p|
              @ps << {id: p.id, size: p.attribute_value('size'), upc: p.attribute_value('upc'), quantity: '10'}
            end

            render :json => @ps.to_json
          else
            render :json => @product.to_json
          end

        }
        format.html
      end

    end

    private

    def distinct_swatches(product)
      product.simple_products.map { |p| p.swatch }.uniq
    end

  end
end