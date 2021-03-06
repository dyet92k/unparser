# frozen_string_literal: true

module Unparser
  class Emitter

    # Arg expr (pattern args) emitter
    class ArgExpr < self

      handle :arg_expr

      children :body

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        visit_parentheses(body)
      end
    end # ArgExpr

    # Arguments emitter
    class Arguments < self
      include Terminated

      handle :args

      SHADOWARGS = ->(node) { node.type.equal?(:shadowarg) }.freeze
      ARG        = ->(node) { node.type.equal?(:arg) }.freeze

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        delimited(normal_arguments)

        write(', ') if procarg_disambiguator?

        return if shadowargs.empty?

        write('; ')
        delimited(shadowargs)
      end

      # Test for procarg_disambiguator
      #
      # @return [Boolean]
      #
      # @api private
      #
      def procarg_disambiguator?
        regular_block? && normal_arguments.all?(&ARG) && normal_arguments.one?
      end

      # Test for regular block
      #
      # @return [Boolean]
      #
      # @api private
      #
      def regular_block?
        parent_type.equal?(:block) && !parent.node.children.first.type.equal?(:lambda)
      end

      # Return normal arguments
      #
      # @return [Enumerable<Parser::AST::Node>]
      #
      # @api private
      #
      def normal_arguments
        children.reject(&SHADOWARGS)
      end
      memoize :normal_arguments

      # Return shadow args
      #
      # @return [Enumerable<Parser::AST::Node>]
      #
      # @api private
      #
      def shadowargs
        children.select(&SHADOWARGS)
      end
      memoize :shadowargs

    end # Arguments

    # Emitter for block and kwrestarg arguments
    class Morearg < self
      include Terminated

      MAP = {
        blockarg:  T_AMP,
        kwrestarg: T_DSPLAT
      }.freeze

      handle :blockarg
      handle :kwrestarg

      children :name

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(MAP.fetch(node_type), name.to_s)
      end

    end # Blockarg

    # Optional argument emitter
    class Optarg < self
      include Terminated

      handle :optarg

      children :name, :value

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(name.to_s, WS, T_ASN, WS)
        visit(value)
      end
    end

    # Optional keyword argument emitter
    class KeywordOptional < self
      include Terminated

      handle :kwoptarg

      children :name, :value

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(name.to_s, T_COLON, WS)
        visit(value)
      end

    end # KeywordOptional

    # Keyword argument emitter
    class Kwarg < self
      include Terminated

      handle :kwarg

      children :name

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(name.to_s, T_COLON)
      end

    end # Restarg

    # Rest argument emitter
    class Restarg < self
      include Terminated

      handle :restarg

      children :name

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(T_SPLAT, name.to_s)
      end

    end # Restarg

    # Argument emitter
    class Argument < self
      include Terminated

      handle :arg, :shadowarg

      children :name

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(name.to_s)
      end

    end # Argument

    # Progarg emitter
    class Procarg < self
      include Terminated

      handle :procarg0

      PARENS = %i[restarg mlhs].freeze

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        if needs_parens?
          parentheses do
            delimited(children)
          end
        else
          delimited(children)
        end
      end

      def needs_parens?
        children.length > 1 || children.any? do |node|
          PARENS.include?(node.type)
        end
      end
    end

    # Block pass node emitter
    class BlockPass < self
      include Terminated

      handle :block_pass

      children :name

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(T_AMP)
        visit(name)
      end

    end # BlockPass

  end # Emitter
end # Unparser
