module Gemgento
  module API
    module SOAP
      module CatalogRule
        class Rule

          def self.fetch_all
            response = list

            if response.success?
              response.body[:result][:item].each do |rule|
                website_ids = rule[:website_ids][:item].is_a?(Array) ? rule[:website_ids][:item] : [rule[:website_ids][:item]]
                user_group_ids = rule[:customer_group_ids][:item].is_a?(Array) ? rule[:customer_group_ids][:item] : [rule[:customer_group_ids][:item]]
                sync_magento_to_local(rule, website_ids, user_group_ids)
              end
            end
          end

          def self.list
            response = MagentoApi.create_call(:catalog_rule_list)

            if response.success? && !response.body[:result][:item].is_a?(Array)
              response.body[:result][:item] = [response.body[:result][:item]]
            end

            return response
          end

          def self.sync_magento_to_local(source, website_ids, user_group_ids)
            price_rule = PriceRule.find_or_initialize_by(magento_id: source[:rule_id])
            price_rule.name = source[:name]
            price_rule.description = source[:description]
            price_rule.from_date = source[:from_date]
            price_rule.to_date = source[:to_date]
            price_rule.is_active = source[:is_active]
            price_rule.stop_rules_processing = source[:stop_rules_processing]
            price_rule.sort_order = source[:sort_order]
            price_rule.simple_action = source[:simple_action]
            price_rule.discount_amount = source[:discount_amount]
            price_rule.sub_is_enable = source[:sub_is_enable]
            price_rule.sub_simple_action = source[:sub_simple_action]
            price_rule.sub_discount_amount = source[:sub_discount_amount]
            price_rule.conditions = source[:conditions]
            price_rule.save

            price_rule.stores = Store.where(website_id: website_ids)
            price_rule.user_groups = UserGroup.where(magento_id: user_group_ids)
          end

        end
      end
    end
  end
end