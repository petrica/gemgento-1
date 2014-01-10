require 'open-uri'

module Gemgento
  module API
    module SOAP
      module Catalog
        class ProductAttributeMedia

          def self.fetch_all
            Gemgento::Product.all.each do |product|
              fetch(product)
            end
          end

          def self.fetch(product)
            product.stores.each do |store|
              media_list = list(product, store)

              unless media_list.nil?
                media_list.each do |product_attribute_media|
                  sync_magento_to_local(product_attribute_media, product, store)
                end
              end
            end
          end

          def self.fetch_all_media_types
            Gemgento::ProductAttributeSet.all.each do |product_attribute_set|
              types(product_attribute_set).each do |media_type|
                sync_magento_media_type_to_local(media_type, product_attribute_set)
              end
            end
          end

          def self.list(product, store)
            message = {
                product: product.magento_id,
                identifier_type: 'id',
                store_view: store.magento_id
            }
            response = Gemgento::Magento.create_call(:catalog_product_attribute_media_list, message)

            if response.success?
              if response.body[:result][:item].nil?
                response.body[:result][:item] = []
              end

              unless response.body[:result][:item].is_a? Array
                response.body[:result][:item] = [response.body[:result][:item]]
              end

              response.body[:result][:item]
            end
          end

          def self.info

          end

          def self.create(asset)
            message = {
                product: asset.product.magento_id,
                data: compose_asset_entity_data(asset, true),
                identifier_type: 'id',
                store_view: asset.store.magento_id
            }
            response = Gemgento::Magento.create_call(:catalog_product_attribute_media_create, message)

            if response.success?
              asset.file = response.body[:result]
            end
          end

          def self.update(asset)
            message = {
                product: asset.product.magento_id,
                file: asset.file,
                data: compose_asset_entity_data(asset, false),
                identifier_type: 'id',
                store_view: asset.store.magento_id
            }
            response = Gemgento::Magento.create_call(:catalog_product_attribute_media_update, message)

            if response.success?
              asset.file = response.body[:result]
            end
          end

          def self.remove(asset)
            message = {product: asset.product.magento_id, file: asset.file, identifier_type: 'id'}
            response = Gemgento::Magento.create_call(:catalog_product_attribute_media_remove, message)

            return response.success?
          end

          def self.types(product_attribute_set)
            response = Gemgento::Magento.create_call(:catalog_product_attribute_media_types, {set_id: product_attribute_set.magento_id})

            if response.success?
              unless response.body[:result][:item].nil? # check if there are any options returned
                unless response.body[:result][:item].is_a? Array # multiple options returned
                  response.body[:result][:item] = [response.body[:result][:item]]
                end
              else
                response.body[:result][:item] = []
              end

              response.body[:result][:item]
            end
          end

          def self.current_store

          end

          private

          # Save Magento product attribute set to local
          def self.sync_magento_to_local(source, product, store)
            asset = Gemgento::Asset.where(product: product, file: source[:file], store: store).first_or_initialize
            asset.url = source[:url]
            asset.position = source[:position]
            asset.label = Gemgento::Magento.enforce_savon_string(source[:label])
            asset.file = source[:file]
            asset.product = product
            asset.sync_needed = false
            asset.set_file(open(source[:url]))

            asset.save

            set_types(source[:types][:item], asset)
          end

          def self.set_types(asset_type_codes, asset)
            asset.asset_types.destroy_all

            # if there is only one category, the returned value is not interpreted array
            unless asset_type_codes.is_a? Array
              asset_type_codes = [Gemgento::Magento.enforce_savon_string(asset_type_codes)]
            end

            # loop through each return category and add it to the product if needed
            asset_type_codes.each do |asset_type_code|
              unless (asset_type_code.empty?)
                asset_type = Gemgento::AssetType.where(product_attribute_set_id: asset.product.product_attribute_set_id, code: asset_type_code).first
                asset.asset_types << asset_type unless asset.asset_types.include?(asset_type) # don't duplicate the asset types
              end
            end
          end

          def self.sync_magento_media_type_to_local(source, product_attribute_set)
            asset_type = Gemgento::AssetType.where(product_attribute_set_id: product_attribute_set.id, code: source[:code]).first_or_initialize
            asset_type.code = source[:code]
            asset_type.scope = source[:scope]
            asset_type.product_attribute_set = product_attribute_set
            asset_type.save
          end

          def self.compose_asset_entity_data(asset, include_file = true)
            asset_entity = {
                label: asset.label,
                position: asset.position,
                types: {item: compose_types(asset)},
                exclude: '0'
            }

            if include_file
              asset_entity[:file] = compose_file_entity(asset.asset_file)
            end

            asset_entity
          end

          def self.compose_file_entity(asset_file)
            if asset_file.file.url(:original) =~ URI::regexp
              content = open(asset_file.file.url(:original)).read
            else
              content = File.open(asset_file.file.path(:original)).read
            end

            file_entity = {
                content: Base64.encode64(content),
                mime: asset_file.file_content_type
            }

            file_entity
          end

          def self.compose_types(asset)
            types = []

            asset.asset_types.each do |asset_type|
              types << asset_type.code
            end

            types
          end

        end
      end
    end
  end
end