(class_specifier
    name: (type_identifier) @className)

(class_specifier
    (base_class_clause
      (type_identifier)@inheritance))

(class_specifier
    body: (field_declaration_list
        (declaration
            declarator: (function_declarator
                declarator: (destructor_name) @destructor))))

(class_specifier
    body: (field_declaration_list
        (declaration
            declarator: (function_declarator
                declarator: (identifier)
                parameters: (parameter_list) @constructorParamList))))

(class_specifier
    name: (type_identifier)
    body: (field_declaration_list
        (field_declaration
            type: [(qualified_identifier) (primitive_type)] @methodType
            declarator: (function_declarator) @methodName)))

(field_declaration
    type: (qualified_identifier) @attributeType
    declarator: (field_identifier) @attributeName)
