module Gemgento

  # @author Gemgento LLC
  class AssetFile < ActiveRecord::Base
    has_many :assets
    has_many :products, through: :assets
    has_many :stores, through: :assets

    has_attached_file :file, styles: {default_index: "200x266>"}

    def save
      # Dirty dirty dirty(S3Bug)..
      begin
        super
      rescue Exception => e
        puts 'Upload Failed once..'

        begin
          super
        rescue Exception => e
          puts 'Upload Failed twice..'

          begin
            super
          rescue Exception => e
            puts 'Upload Failed three times..'

            super
          end
        end
      end
    end
  end
end