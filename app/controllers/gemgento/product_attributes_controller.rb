module Gemgento
  class ProductAttributesController < BaseController

    def update
      @product_attribute = Gemgento::ProductAttribute.find_or_initialize_by(magento_id: params[:id])
      data = params[:data]

      @product_attribute.magento_id = data[:attribute_id]
      @product_attribute.code = data[:atribute_code]
      @product_attribute.frontend_input = data[:frontend_input]
      @product_attribute.default_value = data[:default_value]
      @product_attribute.scope = data[:scope]
      @product_attribute.is_unique = data[:is_unique].to_i == 1 ? true : false
      @product_attribute.is_required = data[:is_required].to_i == 1 ? true : false
      @product_attribute.is_configurable = data[:is_configurable].to_i == 1 ? true : false
      @product_attribute.is_searchable = data[:is_searchable].to_i == 1 ? true : false
      @product_attribute.is_visible_in_advanced_search = data[:is_visible_in_advanced_search].to_i == 1 ? true : false
      @product_attribute.is_comparable = data[:is_comparable].to_i == 1 ? true : false
      @product_attribute.is_used_for_promo_rules = data[:is_used_for_promo_rules].to_i == 1 ? true : false
      @product_attribute.is_visible_on_front = data[:is_visible_on_front].to_i == 1 ? true : false
      @product_attribute.used_in_product_listing = data[:used_in_product_listing].to_i == 1 ? true : false
      @product_attribute.save

      data[:options].each do |store_options|
        @store = Gemgento::Store.find_by(magento_id: store_options[:store_id])

        if @store
          store_options[:options].each do |option|
            @product_attribute_option = Gemgento::ProductAttributeOption.find_or_initialize_by(value: option[:value], store: @store)
            @product_attribute_option.value = option[:value]
            @product_attribute_option.label = option[:label]
            @product_attribute_option.store = @store
            @product_attribute_option.save
          end
        end
      end

      render nothing: true
    end

    private

    def self.

        end
    end