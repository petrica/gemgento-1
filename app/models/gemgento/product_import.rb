module Gemgento

  # @author Gemgento LLC
  class ProductImport < Import
    # TODO: test product import validator
    # validates_with ProductImportValidator

    def default_options
      {
          image_labels: [],
          image_file_extensions: [],
          image_types: [],
          image_path: nil,
          product_attribute_set_id: nil,
          store_id: nil,
          root_category_id: nil,
          simple_product_visibility: 1,
          configurable_product_visibility: 1,
          set_default_inventory_values: false,
          include_images: false,
          configurable_attribute_ids: []
      }
    end

    def image_labels_raw
      image_labels.join("\n")
    end

    def image_labels_raw=(values)
      options[:image_labels] = values.gsub("\r", '').split("\n")
    end

    def image_file_extensions_raw
      image_file_extensions.join(', ')
    end

    def image_file_extensions_raw=(values)
      options[:image_file_extensions] = values.gsub(' ', '').split(',')
    end

    def image_types_raw
      image_types.join("\n")
    end

    def image_types_raw=(values)
      options[:image_types] = values.gsub("\r", '').split("\n")
    end

    def product_attribute_set
      if options[:product_attribute_set_id].nil?
        nil
      else
        @product_attribute_set ||= Gemgento::ProductAttributeSet.find(options[:product_attribute_set_id])
      end
    end

    def store
      if options[:store_id].nil?
        nil
      else
        @store ||= Gemgento::Store.find(options[:store_id])
      end
    end

    def root_category
      if options[:root_category_id].nil?
        nil
      else
        @root_category ||= Gemgento::Category.find(options[:root_category_id])
      end
    end

    def configurable_attributes
      @configurable_attributes ||= Gemgento::ProductAttribute.where(is_configurable: true, id: options[:configurable_attribute_ids])
    end

    def process
      # TODO: update product import process methods
      Rails.logger.info 'Starting to process product import'

      @worksheet = Spreadsheet.open(self.spreadsheet.path).worksheet(0)
      @headers = get_headers
      @index = 0

      associated_simple_products = []

      self.import_errors = []
      self.count_created = 0
      self.count_updated = 0

      1.upto @worksheet.last_row_index do |index|
        @index = index
        @row = @worksheet.row(@index)

        Rails.logger.info "Working on row #{@index}"
        Rails.logger.debug @row

        next if @row[@headers.index('sku').to_i].to_s.strip.blank? # skip blank skus

        if @row[@headers.index('magento_type').to_i].to_s.strip.casecmp('simple') == 0
          simple_product = create_simple_product
          break if simple_product.errors.any?
          associated_simple_products << create_simple_product
        else
          configurable_product = create_configurable_product(associated_simple_products)
          break if configurable_product.errors.any?
          associated_simple_products = []
        end
      end


      ProductImport.skip_callback(:commit, :after, :process)
      self.save validate: false
      ProductImport.set_callback(:commit, :after, :process)
    end

    private

    def get_headers
      accepted_headers = []

      @worksheet.row(0).each do |h|
        unless h.nil?
          accepted_headers << h.downcase.gsub(' ', '_').strip
        end
      end

      accepted_headers
    end

    # Create/Update a simple product.
    #
    # @return [Gemgento::Product]
    def create_simple_product
      sku = @row[@headers.index('sku').to_i].to_s.strip

      product = Product.where(sku: sku).not_deleted.first_or_initialize

      if product.magento_id.nil?
        self.count_created += 1
      else
        self.count_updated += 1
      end

      product.magento_type = 'simple'
      product.sku = sku
      product.product_attribute_set = self.product_attribute_set
      product.stores << self.store unless product.stores.include?(self.store)
      product.status = @row[@headers.index('status').to_i].to_i

      unless product.magento_id
        product.sync_needed = false
        product.save
      end

      product = set_attribute_values(product)
      set_categories(product)

      product.sync_needed = true

      if !product.save
        self.import_errors << "ERROR - row #{@index} - COULD NOT CREATE MAGENTO PRODUCT'"
        self.import_errors << product.errors.full_messages.join(', ')
      else
        create_images(product) if self.include_images?
        set_default_config_inventories(product) if self.set_default_inventory_values?
      end

      return product
    end

    def set_attribute_values(product)
      @headers.each do |attribute_code|
        next if %w[sku status image visibility magento_type category].include?(attribute_code)

        # apply the attribute value if the attribute exists
        if product_attribute = ProductAttribute.find_by(code: attribute_code) # try to load attribute associated with column header

          if product_attribute.frontend_input == 'select'
            label = @row[@headers.index(attribute_code).to_i].to_s.strip
            label = label.gsub('.0', '') if label.end_with? '.0'
            attribute_option = ProductAttributeOption.find_by(product_attribute_id: product_attribute.id, label: label, store: self.store)

            if attribute_option.nil?
              attribute_option = create_attribute_option(product_attribute, label)
            end

            value = attribute_option.nil? ? nil : attribute_option.value

          else # attribute value may have to be associated with an attribute option id
            value = @row[@headers.index(attribute_code).to_i].to_s.strip
            value = value.gsub('.0', '') if value.end_with? '.0'
          end

          if value.nil?
            self.import_errors << "ERROR: row #{@index} - Unknown attribute value '#{@row[@headers.index(attribute_code).to_i].to_s.strip}' for code '#{attribute_code}'"
          else
            product.set_attribute_value(product_attribute.code, value, self.store)
          end


        else
          self.import_errors << "ERROR - row #{@index} - Unknown attribute code, '#{attribute_code}'"
        end
      end

      product = set_default_attribute_values(product)

      return product
    end

    def create_attribute_option(product_attribute, option_label)
      attribute_option = Gemgento::ProductAttributeOption.new
      attribute_option.product_attribute = product_attribute
      attribute_option.label = option_label
      attribute_option.store = self.store
      attribute_option.sync_local_to_magento

      return Gemgento::ProductAttributeOption.find_by(product_attribute: product_attribute, label: option_label, store: self.store)
    end

    def set_default_attribute_values(product)
      product.status = 1 if product.status.nil?
      product.visibility = self.simple_product_visibility.to_i

      if product.url_key.nil?
        url_key = product.name.to_s.strip.gsub(' ', '-').gsub(/[^\w\s]/, '').downcase
        product.set_attribute_value('url_key', url_key)
      end

      return product
    end

    def set_categories(product)
      categories = @row[@headers.index('category').to_i].to_s.strip.split('&')

      categories.each do |category_string|
        category_string.strip!
        subcategories = category_string.split('>')
        parent_id = self.root_category.id

        subcategories.each do |category_url_key|
          category_url_key.strip!
          category = Category.find_by(url_key: category_url_key, parent_id: parent_id)

          unless category.nil?
            product_category = ProductCategory.find_or_initialize_by(category: category, product: product, store: self.store)
            product_category.save
            parent_id = category.id
          else
            self.import_errors << "ERROR - row #{@index} - Unknown category url key '#{category_url_key}' - skipped"
          end
        end
      end
    end

    def create_images(product)
      product.assets.where(store: self.store).destroy_all

      images_found = false
      # find the correct image file name and path
      self.image_labels.each_with_index do |label, position|

        self.image_file_extensions.each do |extension|
          file_name = self.image_path + @row[@headers.index('image').to_i].to_s.strip + '_' + label + extension
          next unless File.exist?(file_name)

          types = []

          unless self.image_types[position].nil?
            types = AssetType.where('product_attribute_set_id = ? AND code IN (?)', self.product_attribute_set.id, self.image_types[position].split(',').map(&:strip))
          end

          unless types.is_a? Array
            types = [types]
          end

          create_image(product, file_name, types, position, label)
          images_found = true
        end
      end

      unless images_found
        self.import_errors << "WARNING: No images found for id:#{product.id}, sku: #{product.sku}"
      end
    end

    def create_image(product, file_name, types, position, label)
      image = Asset.new
      image.product = product
      image.store = self.store
      image.position = position
      image.label = label
      image.set_file(File.open(file_name))

      types.each do |type|
        image.asset_types << type
      end

      image.sync_needed = false
      image.save

      image.sync_needed = true
      image.save

      image
    end

    # Create/Update a configurable product.
    #
    # @return [Gemgento::Product]
    def create_configurable_product(simple_products)
      sku = @row[@headers.index('sku').to_i].to_s.strip

      # set the default configurable product attributes
      configurable_product = Product.where(sku: sku).not_deleted.first_or_initialize

      if configurable_product.magento_id.nil?
        self.count_created += 1
      else
        self.count_updated += 1
      end

      configurable_product.magento_type = 'configurable'
      configurable_product.sku = sku

      configurable_product.product_attribute_set = product_attribute_set
      configurable_product.status = @row[@headers.index('status').to_i].to_i
      configurable_product.stores << store unless configurable_product.stores.include?(store)
      configurable_product.sync_needed = false
      configurable_product.save

      # associate all simple products with the new configurable product
      simple_products.each do |simple_product|
        configurable_product.simple_products << simple_product unless configurable_product.simple_products.include?(simple_product)
      end

      # add the configurable attributes
      configurable_attributes.each do |configurable_attribute|
        configurable_product.configurable_attributes << configurable_attribute unless configurable_product.configurable_attributes.include? configurable_attribute
      end

      # set the additional configurable product details
      set_attribute_values(configurable_product)
      set_categories(configurable_product)

      configurable_product.visibility = self.configurable_product_visibility.to_i

      # push to magento
      configurable_product.sync_needed = true

      if !configurable_product.save
        self.import_errors << "ERROR - row #{@index} - COULD NOT CREATE MAGENTO PRODUCT'"
        self.import_errors << configurable_product.errors.full_messages.join(', ')
      else
        # add the images
        create_configurable_images(configurable_product) if include_images
      end

      return configurable_product
    end

    def create_configurable_images(configurable_product)
      configurable_product.assets.where(store: self.store).destroy_all
      default_product = configurable_product.simple_products.first

      default_product.assets.where(store: self.store).each do |asset|
        asset_copy = Asset.new
        asset_copy.product = configurable_product
        asset_copy.store = self.store
        asset_copy.set_file(File.open(asset.asset_file.file.path(:original)))
        asset_copy.label = asset.label
        asset_copy.position = asset.position
        asset_copy.asset_types = asset.asset_types

        asset_copy.sync_needed = false
        asset_copy.save

        asset_copy.sync_needed = true
        asset_copy.save
      end
    end

    # @param product [Gemgento::Product]
    # @return [void]
    def set_default_config_inventories(product)
      inventory = product.inventories.find_or_initialize_by(store: self.store)
      inventory.use_config_manage_stock = true
      inventory.use_config_backorders = true
      inventory.use_config_min_qty = true
      inventory.sync_needed = true
      inventory.save
    rescue ActiveRecord::RecordNotUnique
      # when Magento pushes inventory data back, it will create missing inventory rows
      set_default_config_inventories(product)
    end

  end
end