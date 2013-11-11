module Gemgento
  module API
    module SOAP
      module Catalog
        class Category

          # Synchronize local database with Magento database
          def self.fetch_all
            sync_magento_tree_to_local(tree)
          end

          def self.tree
            response = Gemgento::Magento.create_call(:catalog_category_tree)

            if response.success?
              return response.body[:tree]
            end
          end

          def self.info(category_id)
            response = Gemgento::Magento.create_call(:catalog_category_info, {category_id: category_id})

            if response.success?
              return response.body[:info]
            end
          end

          def self.create(category)
            data = {
                name: self.name,
                'is_active' => category.is_active ? 1 : 0,
                'include_in_menu' => category.include_in_menu ? 1 : 0,
                'available_sort_by' => {'arr:string' => %w[name]},
                'default_sort_by' => 'name',
                'url_key' => category.url_key,
                'position' => category.position,
                'is_anchor' => 1
            }
            message = {parentId: category.parent.magento_id, categoryData: data}
            response = Gemgento::Magento.create_call(:catalog_category_create, message)

            if response.success?
              category.magento_id = response.body[:attribute_id]
              category.sync_needed = false
              category.save
            end
          end

          def self.update(category)
            data = {
                name: category.name,
                'is_active' => category.is_active ? 1 : 0,
                'include_in_menu' => category.include_in_menu ? 1 : 0,
                'url_key' => category.url_key,
                'position' => category.position
            }
            message = {categoryId: category.magento_id, categoryData: data}
            response = Gemgento::Magento.create_call(:catalog_category_update, message)
            response.body
          end

          def self.assigned_products(category)
            message = {
                categoryId: category.magento_id,
                storeId: Gemgento::Store.current.magento_id
            }
            response = Gemgento::Magento.create_call(:catalog_category_assigned_products, message)

            if response.success? && !response.body[:result][:item].nil?
              result = response.body[:result][:item]
              result = [result] unless result.is_a? Array

              return result
            else
              return false
            end
          end

          def self.set_product_categories
            Gemgento::Category.all.each do |category|
              next if category.products.empty?

              result = assigned_products(category)

              if result.nil? || result == false || result.empty?
                category.products.clear
                next
              end

              product_ids = []
              result.each do |item|
                product = Gemgento::Product.find_by(magento_id: item[:product_id])
                next if product.nil?

                product_ids << item[:product_id]
                pairing = Gemgento::ProductCategory.where(category: category, product: product).first_or_initialize
                pairing.position = item[:position].nil? ? 1 : item[:position]
                pairing.save
              end

              #category.products.destroy(category.products.where("product_id NOT IN (?)", product_ids))
            end
          end

          private

          # Traverse Magento category tree while synchronizing with local category tree
          #
          # @param [Hash] category  The returned item of Magento API call
          def self.sync_magento_tree_to_local(category)
            sync_magento_to_local(info(category[:category_id]))

            if category[:children][:item]
              category[:children][:item] = [category[:children][:item]] unless category[:children][:item].is_a? Array
              category[:children][:item].each do |child|
                sync_magento_tree_to_local(child)
              end
            end
          end

          # Synchronize the response of a catalogCategoryInfo API call to local database
          #
          # @param [Hash] subject The returned item of Magento API call
          def self.sync_magento_to_local(subject)
            category = Gemgento::Category.where(magento_id: subject[:category_id]).first_or_initialize
            category.magento_id = subject[:category_id]
            category.name = subject[:name]
            category.url_key = subject[:url_key]
            category.parent = Gemgento::Category.find_by(magento_id: subject[:parent_id])
            category.position = subject[:position]
            category.is_active = subject[:is_active]
            category.include_in_menu = subject[:include_in_menu] == 1 ? true : false
            category.children_count = subject[:children_count]

            if category.children_count > 0
              category.all_children = subject[:all_children]
            else
              category.all_children = ''
            end

            category.sync_needed = false
            category.save
          end
        end
      end
    end
  end
end