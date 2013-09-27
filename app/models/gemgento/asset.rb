module Gemgento
  class Asset < ActiveRecord::Base
    belongs_to :product, touch: true, class_name: 'Gemgento::Product'
    has_and_belongs_to_many :asset_types, -> { uniq }, :join_table => 'gemgento_assets_asset_types'
    after_save :sync_local_to_magento
    before_destroy :delete_magento
    has_attached_file :attachment,
                      :styles => {:mini => '32x32>', :normal => '172x172>'},
                      :default_style => :normal,
                      :url => "/system/assets/products/:id/:style/:filename",
                      :path => ":rails_root/public/system/assets/products/:id/:style/:filename"

    private

    def sync_local_to_magento
      if self.sync_needed
        API::SOAP::Catalog::ProductAttributeMedia.create(self)
        self.sync_needed = false
        self.save
      end
    end

    def delete_magento
      unless self.file.nil?
        API::SOAP::Catalog::ProductAttributeMedia.remove(self)
      end

      self.asset_types.clear
    end

  end
end