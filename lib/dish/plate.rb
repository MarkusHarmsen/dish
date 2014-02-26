module Dish
  class Plate
    class << self
      def coercions
        @coercions ||= Hash.new(Plate)
      end

      def coerce(key, klass_or_proc)
        coercions[key.to_s] = klass_or_proc
      end
    end

    def initialize(hash)
      @_original_hash = Hash[hash.map { |k, v| [k.to_s, v] }]
    end

    def method_missing(method, *args, &block)
      method = method.to_s
      if method.end_with? '?'
        key = method[0..-2]
        _check_for_presence(key)
      elsif method.end_with? '='
        key = camel_case_key[0..-2]
        _set_value(key, args.first)
      else
        _get_value(method)
      end
    end

    def methods(regular = true)
      valid_keys = as_hash.keys.map(&:to_sym)
      valid_keys + super
    end

    def as_hash
      @_original_hash
    end

    private

      attr_reader :_original_hash

      def _get_value(key)
        value = _original_hash[key]
        _convert_value(value, self.class.coercions[key])
      end

      def _set_value(key, value)
        value = _convert_value(value, self.class.coercions[key])
        @_original_hash[key] = value
      end
 
      def _check_for_presence(key)
        !!_get_value(key)
      end

      def _convert_value(value, coercion)
        case value
        when Array then value.map { |v| _convert_value(v, coercion) }
        when Hash
          if coercion.is_a?(Proc)
            coercion.call(value)
          else
            coercion.new(value)
          end
        else
          if coercion.is_a?(Proc)
            coercion.call(value)
          else
            value
          end
        end
      end
  end
end
