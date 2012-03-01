require "format_fallback/version"

module ActionView
  class PathSet < Array

    def find_with_default_template(*args)
      path = args[0]
      prefix = args[1]
      partial = args[2]
      details = args[3] || {}
      key = args[4]
      if prefix == "layouts"
        # Layouts have their own way of managing fallback, better leave them alone
        find_without_default_template(*args)
      else
        begin
          find_without_default_template(*args)
        rescue MissingTemplate => e
          raise e if details[:formats] == [:html]
          html_args = args.dup
          html_args[3] = details.dup.merge(:formats => [:html])
          find_without_default_template(*html_args)
        end
      end
    end
    alias_method_chain :find, :default_template

  end
  
  # class Resolver
  #   
  #   def cached(key, prefix, name, partial)
  #     return yield unless key && caching?
  #     cache_content = yield
  #     if cache_content.empty?
  #       []
  #     else
  #       @cached[key][prefix][name][partial] ||= cache_content
  #     end
  #   end
  #   
  # end
  class Resolver
    def cached_with_default_template(key, path_info, details, locals)
      name, prefix, partial = path_info
      locals = sort_locals(locals)
      
      if key && caching? && !@cached[key][name][prefix][partial][locals]
        # We need to cache, but let's make sure we're not caching emptiness
        result = decorate(yield, path_info, details, locals)
        @cached[key][name][prefix][partial][locals] = result unless result.empty?
      else
        result = cached_without_default_template(key, path_info, details, locals) do
          yield
        end
      end
      result
    end
    alias_method_chain :cached, :default_template
  end
end
