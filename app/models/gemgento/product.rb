module Gemgento
  class Product < ActiveRecord::Base

    # TODO: handle 'set type' the Gemgento way
    # TODO: handle 'store view' the Gemgento way
    # TODO: handle dynamic size of additional attributes the Gemgento way
    # TODO: undo temporary migration for additional product attributes Product.quality/design/color/size
    # TODO: need a way to update product type via Gemgento (look into has_options)

    belongs_to :product_attribute_set
    has_many :product_attribute_values
    #has_many :product_attributes, :through => :product_attribute_values
    has_and_belongs_to_many :categories, :join_table => 'gemgento_categories_products'
    has_many :assets

    def self.index
      if Product.find(:all).size == 0
        fetch_all
      end
      Product.find(:all)
    end

    def self.fetch_all
      response = Gemgento::Magento.create_call(:catalog_product_list)
      response[:store_view][:item].each_with_index do |product, i|
        info_response = Gemgento::Magento.create_call(:catalog_product_info, { product: product[:product_id], productIdentifierType: 'id' })
        # save/update the product
        sync_magento_to_local(info_response[:info])
      end
    end

    def self.test_attribute_call
      response = Gemgento::Magento.create_call(:catalog_product_list_of_additional_attributes, {productType: 'simple', attributeSetId: '1'})
      puts response
    end

    private

    def self.sync_magento_to_local(subject)
      product = Product.find_or_initialize_by_magento_id(subject[:product_id])
      product.magento_id = subject[:product_id]
      product.magento_type = subject[:type]
      product.name = subject[:name]
      product.url_key = subject[:url_key]
      product.price = subject[:price]
      product.sku = subject[:sku]
      product.sync_needed = false
      product.categories << Category.find_by_magento_id(subject[:categories][:item])
      product.productAttributeSet << Gemgento::ProductAttributeSet.find_by_magento_id(subject[:set])

      # additional attributes
      additional_attributes = parse_additional_attributes(subject[:additional_attributes][:item])
      product.quality = additional_attributes[:quality]
      product.color = additional_attributes[:color]
      product.design = additional_attributes[:pattern]

      # media assets
      image_response = Gemgento::Magento.create_call(:catalog_product_attribute_media_list, { product: product.magento_id, productIdentifierType: 'id' })
      if image_response[:result][:item] != nil &&

          if image_response[:result][:item].size > 1

            image_response[:result][:item].each_with_index do |img, i|
              create_asset(img, p)
            end

          else
            img = image_response.body[:catalog_product_attribute_media_list_response][:result][:item]
            create_asset(img, p)
          end

      end

      product.save
    end

    def self.create_asset(img, p)
      puts 'IMG?: '+img.inspect
      a = Gemgento::Asset.new
      a.url = img[:url]
      a.position = img[:position]
      a.product_id = p.id
      a.save
    end

    def self.parse_additional_attributes(additional_attributes)
      attributes = Hash.new

      additional_attributes.each do |attribute|
        attributes[attribute[:key]] = attribute[:value]
      end

      attributes
    end

    # Push local product changes to magento
    def sync_local_to_magento
      if self.sync_needed
        if !self.magento_id
          create_magento
        else
          update_magento
        end

        self.sync_needed = false
        self.save
      end
    end

    # Create a new Product in Magento and set out magento_id
    def create_magento
      product_data = {
          name: self.name,
          'url_key' => self.url_key,
          'price' => self.price,
          'additional_attributes' => {
            quality: self.quality,
            pattern: self.design,
            color: self.color,
            size: self.size,
            'style_code' => self.style_code
          }
      }
      message = { type: self.magento_type, set: self.set, sku: self.sku, productData: product_data, storeView: self.store_view  }
      create_response = Gemgento::Magento.create_call(:catalog_product_create, message)
      self.magento_id = create_response[:attribute_id]
    end

    # Update existing Magento Product
    def update_magento
      product_data = {
          name: self.name,
          'url_key' => self.url_key,
          'price' => self.price,
          'additional_attributes' => {
              quality: self.quality,
              pattern: self.design,
              color: self.color,
              size: self.size,
              'style_code' => self.style_code
          }
      }
      message = { product: self.magento_id, productIdentifierType: 'id', productData: product_data}
      create_response = Gemgento::Magento.create_call(:catalog_category_update, message)
    end
  end
end