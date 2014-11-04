module Gemgento

  # @author Gemgento LLC
  class Sync < ActiveRecord::Base
    scope :active, -> { where(is_complete: false) }

    def self.locations
      API::SOAP::Directory::Country.fetch_all
      API::SOAP::Directory::Region.fetch_all
    end

    def self.stores
      API::SOAP::Miscellaneous::Store.fetch_all
    end

    def self.categories
      current = create_current('categories')

      API::SOAP::Catalog::Category.fetch_all

      current.complete
    end

    def self.attributes
      current = create_current('attributes')

      API::SOAP::Catalog::ProductAttributeSet.fetch_all
      API::SOAP::Catalog::ProductAttribute.fetch_all
      API::SOAP::Catalog::ProductAttributeMedia.fetch_all_media_types

      current.complete
    end

    def self.products(skip_existing = false)
      last_updated = Sync.where('subject IN (?) AND is_complete = ?', %w[products everything], 1).order('created_at DESC').first
      last_updated = last_updated.created_at.to_s(:db) unless last_updated.nil?
      current = create_current('products')

      API::SOAP::Catalog::Product.fetch_all last_updated
      API::SOAP::Catalog::Category.set_product_categories

      current.complete
    end

    def self.inventory
      current = create_current('inventory')
      API::SOAP::CatalogInventory::StockItem.fetch_all
      current.complete
    end

    def self.customers
      last_updated = Sync.where('subject IN (?) AND is_complete = ?', %w[customers everything], 1).order('created_at DESC').first
      last_updated = last_updated.created_at.to_s(:db) unless last_updated.nil?
      current = create_current('customers')

      API::SOAP::Customer::Customer.fetch_all_customer_groups
      API::SOAP::Customer::Customer.fetch_all last_updated

      current.complete
    end

    def self.orders
      last_updated = Sync.where('subject IN (?) AND is_complete = ?', %w[orders everything], 1).order('created_at DESC').first
      last_updated = last_updated.created_at.to_s(:db) unless last_updated.nil?
      current = create_current('orders')

      API::SOAP::Sales::Order.fetch_all last_updated

      current.complete
    end

    def self.everything
      current = create_current('everything')

      API::SOAP::Directory::Country.fetch_all
      API::SOAP::Directory::Region.fetch_all
      API::SOAP::Miscellaneous::Store.fetch_all
      API::SOAP::Catalog::Category.fetch_all
      API::SOAP::Catalog::ProductAttributeSet.fetch_all
      API::SOAP::Catalog::ProductAttribute.fetch_all
      API::SOAP::Catalog::ProductAttributeMedia.fetch_all_media_types
      API::SOAP::Catalog::Product.fetch_all
      API::SOAP::Catalog::Category.set_product_categories
      API::SOAP::CatalogInventory::StockItem.fetch_all
      API::SOAP::Customer::Customer.fetch_all_customer_groups
      API::SOAP::Customer::Customer.fetch_all
      API::SOAP::Sales::Order.fetch_all

      current.complete
    end

    def complete
      self.is_complete = true
      self.save
    end

    def self.is_active?(subject = nil)
      if subject.nil?
        return !Sync.active.empty?
      else
        return !Sync.where('subject IN (?)', subject).active.empty?
      end
    end

    def self.end_all
      Sync.update_all('is_complete = 1')
    end

    private

    def self.create_current(subject)
      current = Sync.new
      current.subject = subject
      current.is_complete = false
      current.save
      current
    end
  end
end