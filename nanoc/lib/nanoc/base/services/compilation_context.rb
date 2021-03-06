# frozen_string_literal: true

module Nanoc
  module Int
    class CompilationContext
      attr_reader :site
      attr_reader :compiled_content_cache
      attr_reader :compiled_content_store

      def initialize(action_provider:, reps:, site:, compiled_content_cache:, compiled_content_store:)
        @action_provider = action_provider
        @reps = reps
        @site = site
        @compiled_content_cache = compiled_content_cache
        @compiled_content_store = compiled_content_store
      end

      def filter_name_and_args_for_layout(layout)
        seq = @action_provider.action_sequence_for(layout)
        if seq.nil? || seq.size != 1 || !seq[0].is_a?(Nanoc::Core::ProcessingActions::Filter)
          raise Nanoc::Int::Errors::UndefinedFilterForLayout.new(layout)
        end

        [seq[0].filter_name, seq[0].params]
      end

      def create_view_context(dependency_tracker)
        Nanoc::ViewContextForCompilation.new(
          reps: @reps,
          items: @site.items,
          dependency_tracker: dependency_tracker,
          compilation_context: self,
          compiled_content_store: @compiled_content_store,
        )
      end

      def assigns_for(rep, dependency_tracker)
        last_content = @compiled_content_store.get_current(rep)
        content_or_filename_assigns =
          if last_content.binary?
            { filename: last_content.filename }
          else
            { content: last_content.string }
          end

        view_context = create_view_context(dependency_tracker)

        content_or_filename_assigns.merge(
          item: Nanoc::CompilationItemView.new(rep.item, view_context),
          rep: Nanoc::CompilationItemRepView.new(rep, view_context),
          item_rep: Nanoc::CompilationItemRepView.new(rep, view_context),
          items: Nanoc::ItemCollectionWithRepsView.new(@site.items, view_context),
          layouts: Nanoc::LayoutCollectionView.new(@site.layouts, view_context),
          config: Nanoc::ConfigView.new(@site.config, view_context),
        )
      end
    end
  end
end
