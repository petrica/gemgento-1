module Gemgento
  class Api::V1::ProductsController < ApplicationController
    include Gemgento::Api::V1::Base

    def index
      if params[:category_id]
        @products = Gemgento::Category.find(params[:category_id]).products(current_store)
      else
        @products = current_store.products.order(:id)
      end

      @products = @products.page(@page[:number]).per(@page[:size])
    end

    def show
      @product = Gemgento::Product.find(params[:id])
    end

  end
end
