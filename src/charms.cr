annotation Memoize
end

class Object
  macro method_added(method)
    {% if method.annotation(Memoize) %}
      memoize method
    {% end %}
  end
end

module MailHelpers
  def mail(email : Carbon::Email.class, *args, **kwargs) : Nil
    email.new(*args, **kwargs).deliver
  end

  def mail_later(email : Carbon::Email.class, *args, **kwargs) : Nil
    email.new(*args, **kwargs).deliver_later
  end
end

class String
  # Source: https://github.com/amberframework/amber/blob/master/src/amber/extensions/string.cr
  def email? : Bool
    !!match(/^[_]*([a-z0-9]+(\.|_*)?)+@([a-z][a-z0-9-]+(\.|-*\.))+[a-z]{2,6}$/)
  end
end

module Lucky
  abstract class Action
    include MailHelpers
  end
end

module Avram
  class Operation
    include MailHelpers
  end

  abstract class SaveOperation(T)
    def record!
      record.not_nil!
    end

    # Patched to ensure callbacks run for update operations even if no
    # column attributes changed.
    #
    # Also to ensure operation is marked as failed if a nested
    # operation rolls back a database transaction
    def save : Bool
      if valid? && persisted? && changes.empty?
        after_save(record!)
        after_commit(record!)
      end

      previous_def
    rescue Rollback
      mark_as_failed
      false
    end

    # Getting rid of default validations in Avram
    #
    # See https://github.com/luckyframework/lucky/discussions/1209#discussioncomment-46030
    #
    # All operations are expected to explicitly define any validations
    # needed
    def valid? : Bool
      before_save
      attributes.all? &.valid?
    end
  end

  # Avram's implementation errors in an update operation:
  #
  # `duplicate key value violates unique constraint
  # "<constraint name>" (PQ::PQError)`
  #
  # `{{ type }}.new(params)` causes `{{ name }}.save` to create
  # (rather than update) a record each time it is called, since
  # no record was passed when the nested operation was instantiated.
  #
  # Ref: https://github.com/luckyframework/avram/blob/master/src/avram/nested_save_operation.cr
  module NestedSaveOperation
    NESTED_SAVE_OPERATIONS = [] of Avram::MarkAsFailed

    macro has_one_create(type_declaration, *, assoc_name)
      {% name = type_declaration.var %}
      {% type = type_declaration.type %}

      {% nested_attributes = type.resolve.constant(:ATTRIBUTES) %}
      {% nested_columns =
        type.resolve.constant(:COLUMN_ATTRIBUTES).reject do |c|
          c[:autogenerated] || c[:name].id == @type.constant(:FOREIGN_KEY).id
        end
      %}

      {% for nested_attribute in nested_attributes %}
        attribute {{ nested_attribute }}
      {% end %}

      {% for nested_column in nested_columns %}
        attribute {{ nested_column[:name].id }} : {{ nested_column[:type].id }}
      {% end %}

      after_save create_nested_{{ name }}

      def create_nested_{{ name }}(saved_record)
        nested = {{ name }}
        nested.{{ @type.constant(:FOREIGN_KEY).id }}.value = saved_record.id

        NESTED_SAVE_OPERATIONS << nested

        unless nested.save
          NESTED_SAVE_OPERATIONS.each &.mark_as_failed
          database.rollback
        end
      end

      def {{ name }}
        {{ type }}.new(
          params,
          {% for nested_attribute in nested_attributes %}
            {{ nested_attribute.var }}: {{ nested_attribute.var }}.value.nil? ?
              Nothing.new :
              {{ nested_attribute.var }}.value.not_nil!,
          {% end %}
          {% for nested_column in nested_columns %}
            {{ nested_column[:name].id }}: {{ nested_column[:name].id }}.value.nil? ?
              Nothing.new :
              {{ nested_column[:name].id }}.value.not_nil!,
          {% end %}
        )
      end
    end

    macro has_one_update(type_declaration, *, assoc_name)
      {% name = type_declaration.var %}
      {% type = type_declaration.type %}

      {% nested_attributes = type.resolve.constant(:ATTRIBUTES) %}
      {% nested_columns =
        type.resolve.constant(:COLUMN_ATTRIBUTES).reject do |c|
          c[:autogenerated] || c[:name].id == @type.constant(:FOREIGN_KEY).id
        end
      %}

      {% for nested_attribute in nested_attributes %}
        attribute {{ nested_attribute }}
      {% end %}

      {% for nested_column in nested_columns %}
        attribute {{ nested_column[:name].id }} : {{ nested_column[:type].id }}
      {% end %}

      after_save update_nested_{{ name }}

      def update_nested_{{ name }}(saved_record)
        nested = {{ name }}(saved_record)

        NESTED_SAVE_OPERATIONS << nested

        unless nested.save
          NESTED_SAVE_OPERATIONS.each &.mark_as_failed
          database.rollback
        end
      end

      def {{ name }}(record)
        {{ type }}.new(
          record.{{ assoc_name.id }}!,
          params,
          {% for nested_attribute in nested_attributes %}
            {{ nested_attribute.var }}: {{ nested_attribute.var }}.value.nil? ?
              Nothing.new :
              {{ nested_attribute.var }}.value.not_nil!,
          {% end %}
          {% for nested_column in nested_columns %}
            {{ nested_column[:name].id }}: {{ nested_column[:name].id }}.value.nil? ?
              Nothing.new :
              {{ nested_column[:name].id }}.value.not_nil!,
          {% end %}
        )
      end
    end
  end

  # Adds `needs` macro to Basic (non-database) operations
  module NeedyInitializer
    macro included
      OPERATION_NEEDS = [] of Nil

      macro inherited
        inherit_needs
      end
    end

    macro needs(type_declaration)
      {% OPERATION_NEEDS << type_declaration %}
      @{{ type_declaration.var }} : {{ type_declaration.type }}
      property {{ type_declaration.var }}
    end

    macro inherit_needs
      \{% if !@type.constant(:OPERATION_NEEDS) %}
        OPERATION_NEEDS = [] of Nil
      \{% end %}

      \{% if !@type.ancestors.first.abstract? %}
        \{% for type_declaration in @type.ancestors.first.constant :OPERATION_NEEDS %}
          \{% OPERATION_NEEDS << type_declaration %}
        \{% end %}
      \{% end %}

      macro inherited
        inherit_needs
      end

      macro finished
        setup_initializer
      end
    end

    macro setup_initializer
      # Build up a list of method arguments
      #
      # This way everything has a name and type and we don't have to rely on
      # **named_args**. **named_args** are easy but you get horrible type errors.
      #
      # attribute_method_args would look something like:
      #
      #   name : String | Nothing = Nothing.new,
      #   email : String | Nil | Nothing = Nothing.new
      #
      # This can be passed to macros as a string, and then the macro can call .id
      # on it to output the string as code!
      {% attribute_method_args = "" %}

      # Build up a list of params so you can use the method args
      #
      # This looks something like:
      #
      #   name: name,
      #   email: email
      {% attribute_params = "" %}

      {% for attribute in ATTRIBUTES %}
        {% attribute_method_args = attribute_method_args + "#{attribute.var} : #{attribute.type} | Nothing = Nothing.new,\n" %}
        {% attribute_params = attribute_params + "#{attribute.var}: #{attribute.var},\n" %}
      {% end %}

      generate_initializers({{ attribute_method_args }}, {{ attribute_params }})
    end

    private class Nothing
    end

    macro generate_initializers(attribute_method_args, attribute_params)
      {% needs_method_args = "" %}
      {% for type_declaration in OPERATION_NEEDS %}
        {% needs_method_args = needs_method_args + "@#{type_declaration},\n" %}
      {% end %}

      def initialize(
          @params : Avram::Paramable,
          {{ needs_method_args.id }}
          {{ attribute_method_args.id }}
        )
        set_attributes({{ attribute_params.id }})
      end

      def initialize(
          {{ needs_method_args.id }}
          {{ attribute_method_args.id }}
        )
        @params = Avram::Params.new
        set_attributes({{ attribute_params.id }})
      end

      def set_attributes({{ attribute_method_args.id }})
        {% for attribute in ATTRIBUTES %}
          unless {{ attribute.var }}.is_a? Nothing
            self.{{ attribute.var }}.value = {{ attribute.var }}
          end
        {% end %}
      end
    end
  end

  abstract class BasicOperation < Operation
    include NeedyInitializer

    def self.submit!(*args, **named_args)
      submit(*args, **named_args) { |_, result| return result.not_nil! }
    rescue
      raise Avram::Rollback.new
    end

    def self.submit(*args, **named_args)
      new(*args, **named_args).submit do |operation, result|
        yield operation, result
      end
    end
  end
end

# There's `avram_enum`, but that saves the enum value as
# `Int32` in the database. The problem is, enum member values are
# order-dependent -- the values change when the member ordering
# changes.
#
# Besides, you couldn't make sense of the numbers if you peeked
# into the database
#
# `__enum` saves enum members as `String` instead.
macro __enum(enum_name, &block)
  enum Raw{{ enum_name }}
    {{ block.body }}
  end

  struct {{ enum_name }}
    def self.adapter
      Lucky
    end

    def initialize(@raw : Raw{{ enum_name }})
    end

    def initialize(value : String)
      @raw = Raw{{ enum_name }}.parse(value)
    end

    def initialize(value : Symbol)
      @raw = initialize(value.to_s)
    end

    delegate :to_s, to: @raw
    forward_missing_to @raw

    module Lucky
      alias ColumnType = String

      include Avram::Type

      def parse(value : {{ enum_name }})
        SuccessfulCast({{ enum_name }}).new(value)
      end

      def parse(value : String)
        SuccessfulCast({{ enum_name }}).new {{ enum_name }}.new(value)
      rescue
        FailedCast.new
      end

      def parse(value : Symbol)
        parse value.to_s
      end

      def to_db(value : {{ enum_name }})
        value.to_s
      end

      class Criteria(T, V) < String::Lucky::Criteria(T, V)
      end
    end
  end
end
