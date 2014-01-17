module Gemgento
  class ProductsController < BaseController

    respond_to :json, :html

    def show
      if (params[:id])
        if params[:updated_at] # only return the product if it was updated since specified timestamp
          @product = Product.includes(:simple_products).where('updated_at > ? AND id = ?', params[:updated_at], params[:id]).first
        else
          @product = Product.includes(:simple_products).find(params[:id])
        end
      else
        if params[:updated_at] # only return the product if it was updated since specified timestamp
          @product = Product.active.where('updated_at > ?', params[:updated_at]).where(
              gemgento_product_attributes: {code: 'url_key'},
              gemgento_product_attribute_values: {value: params[:url_key]},
          ).first include: :simple_products
        else
          @product = Product.active.where(
              gemgento_product_attributes: {code: 'url_key'},
              gemgento_product_attribute_values: {value: params[:url_key]},
          ).first include: :simple_products
        end

        @product.product_attribute_values.reload unless @product.nil?
      end

      respond_with @product
    end

    def update
      data = params[:data]

      @product = Gemgento::Product.where('id = ? OR magento_id = ?', params[:id], data[:product_id]).first_or_initialize
      @product.magento_id = data[:product_id]
      @product.magento_type = data[:type]
      @product.sku = data[:sku]
      @product.sync_needed = false
      @product.product_attribute_set = Gemgento::ProductAttributeSet.where(magento_id: data[:set]).first
      @product.magento_type = data[:type]
      @product.save

      set_stores(data[:stores], @product) unless data[:stores].nil?

      unless data[:additional_attributes].nil?
        set_assets(data[:additional_attributes], @product)
        set_attribute_values_from_magento(data[:additional_attributes], @product)
      end

      set_associated_products(data[:simple_product_ids], data[:configurable_product_ids], @product)

      render nothing: true
    end

    def destroy
      data = params[:data]

      if Gemgento::Product.where('id = ? OR magento_id = ?', params[:id], data[:product_id]).count > 0
        @product = Gemgento::Product.where('id = ? OR magento_id = ?', params[:id], data[:product_id]).first.mark_deleted!
      end

      render nothing: true
    end

    private

    def set_stores(magento_stores, product)
      product.stores.clear

      magento_stores.each do |magento_id|
        product.stores << Gemgento::Store.find_by(magento_id: magento_id)
      end

      product.save
    end

    def set_attribute_values_from_magento(magento_attribute_values, product)
      magento_attribute_values.each do |store_id, attribute_values|
        store = Gemgento::Store.find_by(magento_id: store_id)

        attribute_values.each do |code, value|

          case code
            when 'visibility'
              product.visibility = value.to_i
              product.save
            when 'status'
              product.status = value.to_i == 1 ? 1 : 0
              product.save
            when 'category_ids'
              puts value.inspect
              set_categories(value, product, store)
            else
              product.set_attribute_value(code, value, store)
          end
        end
      end
    end

    def set_categories(magento_categories, product, store)
      Gemgento::ProductCategory.unscoped.where(store: store, product: product).destroy_all

      puts magento_categories.inspect
      # loop through each return category and add it to the product if needed
      unless magento_categories.nil?
        magento_categories.each do |magento_category|
          category = Gemgento::Category.find_by(magento_id: magento_category)
          product_category = Gemgento::ProductCategory.new
          product_category.category = category
          product_category.product = product
          product_category.store = store
          product_category.save
        end
      end

      product.save
    end

    def set_assets(magento_source_assets, product)
      magento_source_assets.each do |store_id, source_assets| # cycle through media galleries for each

        if !source_assets[:media_gallery].nil? && !source_assets[:media_gallery][:images].nil?
          store = Gemgento::Store.find_by(magento_id: store_id)
          media_gallery = source_assets[:media_gallery][:images]

          media_gallery.each do |source| # cycle through the store specific assets
            asset = Gemgento::Asset.unscoped.find_or_initialize_by(product_id: product.id, file: source[:file], store: store)

            if !source[:removed].nil? && source[:removed] == 0

              if source[:new_file].nil?
                url = source[:url]
                file = source[:file]
              else
                url = "http://#{Gemgento::Config[:magento][:url]}/media/catalog/product#{source[:new_file]}"
                file = source[:new_file]
              end

              asset.url = url
              asset.position = source[:position]
              asset.label = source[:label]
              asset.file = file
              asset.product = product
              asset.sync_needed = false
              asset.set_file(open(url))
              asset.store = store
              asset.save

            elsif !source[:removed].nil? && source[:removed] == 1
              asset.destroy
            end
          end
        end
      end
    end

    def set_associated_products(simple_magento_product_ids, configurable_magento_product_ids, product)
      set_simple_products(simple_magento_product_ids, product) unless simple_magento_product_ids.nil?
      set_configurable_products(configurable_magento_product_ids, product) unless configurable_magento_product_ids.nil?
    end

    def set_simple_products(magento_ids, product)
      simple_product_ids = []

      magento_ids.each do |magento_id|
        simple_product = Gemgento::Product.find_by(magento_id: magento_id)
        next if product.nil?

        product.simple_products << simple_product unless product.simple_products.include? simple_product
        simple_product_ids << simple_product.id
      end

      product.simple_products.where('simple_product_id NOT IN (?)', simple_product_ids).clear
    end

    def set_configurable_products(magento_ids, product)
      configurable_product_ids = []

      magento_ids.each do |magento_id|
        configurable_product = Gemgento::Product.find_by(magento_id: magento_id)
        next if product.nil?

        product.configurable_products << configurable_product unless product.configurable_products.include? configurable_product
        configurable_product_ids << configurable_product.id
      end

      product.configurable_products.where('configurable_product_id NOT IN (?)', configurable_product_ids).clear
    end

  end
end