module Gemgento

  # @author Gemgento LLC
  class ProductAttribute < ActiveRecord::Base
    has_and_belongs_to_many :product_attribute_sets, -> { uniq },
                            :join_table => 'gemgento_attribute_set_attributes'
    has_and_belongs_to_many :configurable_products, -> { uniq },
                            join_table: 'gemgento_configurable_attributes',
                            class_name: 'Product'

    has_many :product_attribute_values
    has_many :product_attribute_options

    after_save :sync_local_to_magento

    default_scope -> { where(deleted_at: nil) }

    def self.ignored
      %w[sku gemgento_id]
    end

    def mark_deleted
      self.deleted_at = Time.now
    end

    def mark_deleted!
      mark_deleted
      self.save
    end

    private

    # Push local product attribute set changes to Magento
    def sync_local_to_magento
      if self.sync_needed
        if !self.magento_id
          API::SOAP::Catalog::ProductAttribute.create(self)
        else
          API::SOAP::Catalog::ProductAttribute.update(self)
        end

        self.sync_needed = false
        self.save
      end
    end

  end
end