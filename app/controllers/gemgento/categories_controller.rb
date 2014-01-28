module Gemgento
  class CategoriesController < BaseController

    respond_to :json, :html

    def index
      root_category = Gemgento::Category.find_by(parent_id: nil)
      @categories = Gemgento::Category.where(include_in_menu: true, parent: root_category, is_active: true)

      if params[:updated_at] # only grab categories that were updated after specified timestamp
        @categories = Gemgento::Category.where('updated_at > ?', params[:updated_at])
      end

      respond_with @categories
    end

    def show
      if params[:updated_at] # only grab the category if it was updated after specified timestamp
        @category = Gemgento::Category.where('updated_at > ? AND id = ?', params[:updated_at], params[:id]).first
      else
        @category = Gemgento::Category.find(params[:id])
      end

      @category.includes_category_products = true unless @category.nil?

      respond_with @category
    end

    def update
      @category = Gemgento::Category.find_or_initialize_by(magento_id: params[:id])
      data = params[:data]

      @category.magento_id = data[:category_id]
      @category.is_active = data[:is_active].to_i == 1 ? true : false
      @category.position = data[:position]
      @category.parent = Gemgento::Category.find_by(magento_id: params[:parent_id]) unless params[:parent_id].nil?
      @category.name = data[:name]
      @category.url_key = data[:url_key]
      @category.include_in_menu = data[:include_in_menu]
      @category.sync_needed = false
      @category.save

      set_stores(data[:store_ids], @category)
      set_products(data[:products], @category)

      render nothing: true
    end

    private

    def set_stores(magento_store_ids, category)
      category.stores.clear

      magento_store_ids.each do |magento_id|
        next if magento_id.to_i == 0 # 0 is the admin store which is not used in Gemgento
        category.stores << Gemgento::Store.find_by(magento_id: magento_id)
      end

      category.save
    end

    def set_products(stores_products, category)
      stores_products.each do |store_id, products|
        next if store_id.to_i == 0 # 0 is the admin store which is not used in Gemgento
        store = Gemgento::Store.find_by(magento_id: store_id)

        product_category_ids = []
        products.each do |item|
          product = Gemgento::Product.find_by(magento_id: item[:product_id])
          next if product.nil?

          pairing = Gemgento::ProductCategory.unscoped.find_or_initialize_by(category: category, product: product, store: store)
          pairing.position = item[:position].nil? ? 1 : item[:position][0]
          pairing.store = store
          pairing.save

          product_category_ids << pairing.id
        end

        Gemgento::ProductCategory.unscoped.
            where('store_id = ? AND category_id = ? AND id NOT IN (?)', store.id, category.id, product_category_ids).
            destroy_all
      end
    end

  end
end
