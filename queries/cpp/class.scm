(namespace_definition name: (nested_namespace_specifier) @namespace)
(namespace_definition name: (namespace_identifier) @namespace)
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
            declarator: [(reference_declarator) (function_declarator)] @methodName)@methodLine))

(class_specifier
    name: (type_identifier)
    body: (field_declaration_list
        (field_declaration
            declarator: [(reference_declarator) (function_declarator)] @methodNameRemove
            default_value: (number_literal) @virtual (#eq? @virtual  "0"))))

(field_declaration
    type: [(qualified_identifier)  (type_identifier)] @attributeType
    declarator: (field_identifier) @attributeName)


