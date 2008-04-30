# Copyright (c) 2008 [Sur http://expressica.com]

module AutoTags
  module ModelHelpers
    module ClassMethods
      def self.extended(base) #:nodoc
        base.send('include', ModelHelpers::InstanceMethods)
      end
      
      # Enables the model class to leverage the automatic tags generation.
      #
      # Available options to this method are...
      # * :include
      #
      # <b>:include</b>
      # It accepts the array of method names. These methods will supply
      # the content for generating the content.
      #
      # Examples:
      #
      #   # sing attribute example
      #   class Vendor < ActiveRecord::Base
      #     auto_tags :include => :product
      #   end
      #
      #   # multiple attributes example
      #   class Vendor < ActiveRecord::Base
      #     auto_tags :include => [:product, :description]
      #   end
      #
      #   # associations example
      #   class Book < ActiveRecord::Base
      #     has_many :authors
      #     auto_tags :include => [:title, :description, :authors_names]
      #     
      #     def authors_names
      #       authors.collect{|a| a.name.join(' ')}
      #     end
      #   end
      def auto_tags(options={})
        AutoTags::AutoTagsGeneration.appid = options[:appid]
        includes = [options[:include]].flatten.compact
        raise AutoTagsIncludeError, "Nothing to include for auto_tags", caller if includes.empty?
        self.send('cattr_accessor', :auto_tags_includes)
        self.auto_tags_includes = includes
      end
    end
    
    module InstanceMethods
    
      # generates relevant tags for the model's object
      def get_auto_tags
        tag_content = []
        raise AutoTagsNotDefinedError, "auto_tags has not been defiend in #{self.class}", caller unless self.class.respond_to?(:auto_tags_includes)
        self.class.auto_tags_includes.each do |caller_id|
          unless self.respond_to?(caller_id)
            raise NoMethodError, "no response to the method #{caller_id}", caller
          else
            tag_content << self.send(caller_id).to_s
          end
        end
        AutoTags::AutoTagsGeneration.generate_tags(tag_content.join(' '))
      end
    end
  end
end

ActiveRecord::Base.send('extend', AutoTags::ModelHelpers::ClassMethods)
