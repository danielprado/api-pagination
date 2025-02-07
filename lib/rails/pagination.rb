module Rails
  module Pagination
    protected

    def paginate(*options_or_collection)
      options    = options_or_collection.extract_options!
      collection = options_or_collection.first

      return _paginate_collection(collection, options) if collection

      response_format = _discover_format(options)

      collection = options[response_format]
      collection = _paginate_collection(collection, options)

      options[response_format] = collection if options[response_format]

      render options
    end

    def paginate_with(collection)
      respond_with _paginate_collection(collection)
    end

    private

    def _discover_format(options)
      for response_format in ApiPagination.config.response_formats
        return response_format if options.key?(response_format)
      end
    end

    def _paginate_collection(collection, options={})
      options[:page] = ApiPagination.config.page_param(params)
      options[:per_page] ||= ApiPagination.config.per_page_param(params)

      collection, pagy = ApiPagination.paginate(collection, options)

      links = (headers['Link'] || '').split(',').map(&:strip)
      url   = base_url + request.script_name + request.path_info
      pages = ApiPagination.pages_from(pagy || collection, options)

      pages.each do |k, v|
        new_params = request.query_parameters.merge(:page => v)
        links << %(<#{url}?#{new_params.to_param}>; rel="#{k}")
      end

      total_header    = ApiPagination.config.total_header
      per_page_header = ApiPagination.config.per_page_header
      page_header     = ApiPagination.config.page_header
      include_total   = ApiPagination.config.include_total

      headers['Link'] = links.join(', ') unless links.empty?
      headers[per_page_header] = options[:per_page].to_s
      headers[page_header] = options[:page].to_s unless page_header.nil?
      headers[total_header] = total_count(pagy || collection, options).to_s if include_total

      return collection
    end

    def total_count(collection, options)
      total_count = if ApiPagination.config.paginator == :kaminari
        paginate_array_options = options[:paginate_array_options]
        paginate_array_options[:total_count] if paginate_array_options
      end
      total_count || ApiPagination.total_from(collection)
    end

    def base_url
      ApiPagination.config.base_url || request.base_url
    end
  end
end
