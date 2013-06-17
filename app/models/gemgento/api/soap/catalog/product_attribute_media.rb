module Gemgento
  module API
    module SOAP
      module Catalog
        class ProductAttributeMedia

          def self.fetch_all
            Gemgento::Product.all.each do |product|
              list(product.magento_id).each do |product_attribute_media|
                sync_magento_to_local(product_attribute_media)
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

          def self.list(product_id)
            response = Gemgento::Magento.create_call(:catalog_product_attribute_set_list)

            unless response[:result][:item].is_a? Array
              response[:result][:item] = [response[:result][:item]]
            end

            response[:result][:item]
          end

          def self.info

          end

          def self.create(asset)
            message = { product: asset.product.magento_id, data: compose_asset_entity_data(asset), identifier_type: 'id' }
            create_response = Gemgento::Magento.create_call(:catalog_product_attribute_media_create, message)
            asset.file = create_response[:result]
          end

          def self.remove(asset)
            message = { product: asset.product.magento_id, file: asset.file, identifier_type: 'id' }
            Gemgento::Magento.create_call(:catalog_product_attribute_media_remove, message)
          end

          def self.types(product_attribute_set)
            response = Gemgento::Magento.create_call(:catalog_product_attribute_media_types, { set_id: product_attribute_set.magento_id })

            unless response[:result][:item].nil? # check if there are any options returned
              unless response[:result][:item].is_a? Array # multiple options returned
                response[:result][:item] = [response[:result][:item]]
              end
            else
              response[:result][:item] = []
            end

            response[:result][:item]
          end

          def self.current_store

          end

          private

          # Save Magento product attribute set to local
          def self.sync_magento_to_local(source)
            asset = Gemgento::Asset.find_or_initialize_by(product_id: product.id, url: source[:url])
            asset.url = source[:url]
            asset.position = source[:position]
            asset.label = Gemgento::Magento.enforce_savon_string(source[:label])
            asset.file = source[:file]
            asset.product = product
            asset.sync_needed = false
            asset.save

            asset.set_types(source[:types][:item])
          end

          def self.sync_magento_media_type_to_local(source, product_attribute_set)
            asset_type = Gemgento::AssetType.find_or_initialize_by(product_attribute_set_id: product_attribute_set.id, code: source[:url])
            asset_type.code = source[:code]
            asset_type.scope = source[:scope]
            asset_type.product_attribute_set = product_attribute_set
            asset_type.save
          end

          def self.compose_asset_entity_data(asset)
            asset_entity = {
                file: compose_file_entity(product_attribute_media),
                label: asset.label,
                position: asset.position,
                types: { item: compose_types(asset) }
            }

            asset_entity
          end

          def self.compose_file_entity(asset)
            file_name = asset.url.split('/')[-1]

            file_entity = {
                content: Base64.encode64(File.open(asset.url).read),
                mime: MIME::Types.type_for(file_name).first.content_type
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