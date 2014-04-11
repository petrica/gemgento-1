module Gemgento
  class CategoriesController < ApplicationController

    respond_to :json, :html

    def index
      @current_category = Gemgento::Category.root
      @categories = Gemgento::Category.top_level
      @products = Gemgento::Product.all

      respond_to do |format|
        format.html
        format.json { render json: @categories.as_json({ store: current_store })  }
      end
    end

    def show
      @current_category = Gemgento::Category.where('id = ? OR url_key = ?', params[:id], params[:url_key]).first || not_found
      current_category.includes_category_products = true

      respond_to do |format|
        format.html
        format.json { render json: current_category.as_json({ store: current_store })  }
      end
    end

  end
end
