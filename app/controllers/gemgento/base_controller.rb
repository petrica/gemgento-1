module Gemgento
  class BaseController < ActionController::Base
    include SslRequirement

    layout :set_layout

    def set_layout(html_layout = 'application', pjax_layout = false)
      if request.url # Check if we are redirected
        response.headers['X-PJAX-URL'] = request.url
      end

      if request.headers['X-PJAX']
        pjax_layout
      else
        html_layout
      end
    end
  end
end

