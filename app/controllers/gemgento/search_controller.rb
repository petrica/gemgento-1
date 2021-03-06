module Gemgento
  class SearchController < ApplicationController

    respond_to :json, :html

    def index
      @results = Gemgento::Search.products(params[:query]).active

      respond_to do |format|
        format.html
        format.json { render json: @results }
      end
    end

  end
end
