return {
  enum_specifier = true,
  class_specifier = true,
  struct_specifier = true,
  field_declaration = true,
  function_definition = true,
  declaration = true,
  preproc_def = true,
  template_declaration = "container",
  namespace_definition = "container",
  linkage_specification = "container",

  -- c++20
  -- https://en.cppreference.com/w/cpp/language/modules.html
  export_declaration = "container",
}
