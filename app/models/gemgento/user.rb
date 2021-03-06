module Gemgento

  # @author Gemgento LLC
  class User < ActiveRecord::Base
    devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

    belongs_to :user_group

    has_many :addresses, as: :addressable, class_name: 'Gemgento::Address'
    has_many :recurring_profiles, class_name: 'Gemgento::RecurringProfile'
    has_many :saved_credit_cards, class_name: 'Gemgento::SavedCreditCard', dependent: :destroy
    has_many :wishlist_items, class_name: 'Gemgento::WishlistItem'
    has_many :orders, class_name: 'Gemgento::Order'
    has_many :products, through: :wishlist_items, class_name: 'Gemgento::Product'

    has_one :shopify_adapter, class_name: 'Adapter::ShopifyAdapter', as: :gemgento_model

    has_and_belongs_to_many :stores, join_table: 'gemgento_stores_users', class_name: 'Store'

    accepts_nested_attributes_for :orders

    attr_accessor :subscribe

    before_validation :manage_subscribe

    before_create :magento_create, if: -> { magento_id.nil? }
    after_save :magento_update, if: Proc.new { |u| u.sync_needed }

    attr_accessor :sync_needed

    default_scope -> { where(deleted_at: nil) }

    validates :magento_id, uniqueness: true, allow_nil: true
    validates :user_group, presence: true

    def name
      "#{self.first_name} #{self.last_name}".strip
    end

    def self.is_valid_login(email, password)

      # If no customer with email is known, double check Magento
      if !Gemgento::User.exists?(email: email) && customer = Gemgento::Magento::CustomerAdapter.find_by(email: email)
        Gemgento::API::SOAP::Customer::Customer.fetch(customer[:customer_id])
      end

      user = User.find_by(email: email)

      if user.nil? || !user.is_valid_password(password)
        user = nil
      end

      user
    end

    def is_valid_password(password)
      unless self.encrypted_password.blank?
        return self.valid_password?(password)
      else
        if self.magento_password.blank? || !self.magento_password.include?(':') # if we don't have any passwords, get them from Magento
          API::SOAP::Customer::Customer.fetch(self.magento_id)
          self.reload
        end

        salt = self.magento_password.split(':')[1]
        encrypted_password = Digest::MD5.hexdigest(salt + password)
        encrypted_password += ':' + salt

        if self.magento_password == encrypted_password
          self.magento_password = nil
          self.password = password
          self.password_confirmation = password
          self.sync_needed = false
          self.save

          return true
        else
          return false
        end
      end
    end

    def is_subscriber?
      return !Subscriber.find_by(email: self.email).nil?
    end

    def mark_deleted
      self.deleted_at = Time.now
    end

    def mark_deleted!
      mark_deleted
      self.save
    end

    def default_billing_address
      self.addresses.find_by(is_billing: true)
    end

    def default_shipping_address
      self.addresses.find_by(is_shipping: true)
    end

    def password_confirmation=(value)
      @password_confirmation = value

      # password changes must be pushed to magento, so that
      # magento customer updates don't revert the password
      self.sync_needed = true
    end

    def as_json(options = nil)
      result = super
      result['is_subscriber'] = self.is_subscriber?

      return result
    end

    def subscribe
      @subscribe ||= self.is_subscriber?
    end

    def manage_subscribe
      self.subscribe = false if self.subscribe == 0 || self.subscribe == '0'
      Subscriber.manage self, self.subscribe
    end

    private

    # Create the user in Magento.  Called as a before_save callback, a failure to create new user in Magento will cancel
    # the transaction and set the Magento response as base error on object.
    #
    # @return [Boolean]
    def magento_create
      response = API::SOAP::Customer::Customer.create(self, self.stores.first)

      if response.success?
        self.magento_id = response.body[:result]
        self.created_in = self.stores.first.name
        return true
      else
        self.errors.add(:base, response.body[:faultstring])
        return false
      end
    end

    def magento_update
      self.stores.each do |store|
        response = API::SOAP::Customer::Customer.update(self, store)

        unless response.success?
          self.errors.add(:base, response.body[:faultstring])
          return false
        end
      end

      return true
    end

  end
end
