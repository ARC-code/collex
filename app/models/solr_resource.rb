class SolrResource < SolrBaseModel
  has_many :properties, :class_name => "SolrProperty"
  column :uri,        :string
    
  # Simplify access to properties by name.  Examples:
  #  resource.title => returns first title property found
  #  resource.titles => returns an array of properties with name "title"
  def method_missing(method_id, *arguments)
    begin
      super
    rescue NoMethodError
      name = method_id.to_s
      singular_name = name.singularize
      props = properties.select {|prop| prop.name == singular_name }
      return name == singular_name ? props[0] : props
    end
  end
  
  def to_mla_citation
    "#{self.mla_authors} <em>#{self.title.value}.</em> MORE TO BE ADDED LATER"
  end
  
  def mla_authors
    mla_names_for(self.role_AUTs)
  end
  
  # This returns a list of names in the "Last, First." format.
  # "First Last" and "Last, First" input are handled
  # TODO handle "Jr", "II", "III", etc suffixes
  def mla_names_for(name_list)
    return "---." if name_list.size < 1
    unformatted_names = name_list.collect{ |auth| auth.value }
    names = unformatted_names.collect do |name|
      if name.include?(", ") then name else n = name.split(" "); n.last + ", " + n[0..-2].join(" ") end
    end
    mla_names = case names.size
    when 1
      names[0]
    when 2
      names.join(" and ")
    else
      names[0..-2].join(", ") + ", and " + names.last
    end
    mla_names << "." unless mla_names[-1].chr == "."
    mla_names
  end
    
end
