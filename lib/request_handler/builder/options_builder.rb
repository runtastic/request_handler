# frozen_string_literal: true

require 'request_handler/builder/base'
require 'request_handler/builder/page_builder'
require 'request_handler/builder/include_options_builder'
require 'request_handler/builder/sort_options_builder'
require 'request_handler/builder/filter_builder'
require 'request_handler/builder/query_builder'
require 'request_handler/builder/body_builder'
require 'request_handler/builder/multipart_builder'
require 'request_handler/builder/fieldsets_builder'

Options = Struct.new(:page, :include_options, :sort_options, :filter, :query, :body,
                     :multipart, :fieldsets)

module RequestHandler
  module Builder
    class OptionsBuilder < Base
      def create_klass_struct
        @result = Options.new
      end

      def page(&block)
        @result.page = build_page(&block)
      end

      def include_options(&block)
        @result.include_options = build_include_options(&block)
      end

      def sort_options(&block)
        @result.sort_options = build_sort_options(&block)
      end

      def filter(&block)
        @result.filter = build_filter(&block)
      end

      def query(&block)
        @result.query = build_query(&block)
      end

      def body(&block)
        @result.body = build_body(&block)
      end

      def multipart(&block)
        @result.multipart = build_multipart(&block)
      end

      def fieldsets(&block)
        @result.fieldsets = build_fieldsets(&block)
      end

      def build_page(&block)
        Docile.dsl_eval(PageBuilder.new, &block).build
      end

      def build_include_options(&block)
        Docile.dsl_eval(IncludeOptionsBuilder.new, &block).build
      end

      def build_sort_options(&block)
        Docile.dsl_eval(SortOptionsBuilder.new, &block).build
      end

      def build_filter(&block)
        Docile.dsl_eval(FilterBuilder.new, &block).build
      end

      def build_query(&block)
        Docile.dsl_eval(QueryBuilder.new, &block).build
      end

      def build_body(&block)
        Docile.dsl_eval(BodyBuilder.new, &block).build
      end

      def build_multipart(&block)
        Docile.dsl_eval(MultipartBuilder.new, &block).build
      end

      def build_fieldsets(&block)
        Docile.dsl_eval(FieldsetsBuilder.new, &block).build
      end
    end
  end
end
