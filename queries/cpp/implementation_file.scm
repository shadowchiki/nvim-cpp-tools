(function_definition
  declarator: (function_declarator
                declarator: (qualified_identifier
                              scope: (namespace_identifier)@className)))

(function_definition 
  type: [(qualified_identifier) (primitive_type)]
  declarator:
    (function_declarator
      parameters:(parameter_list)@methodParameters))

(function_definition
  type: [(qualified_identifier) (primitive_type)]@methodType
  declarator: (function_declarator
                declarator: (qualified_identifier
                              name: (identifier)@methodName)))

(function_definition
  type: [(qualified_identifier) (primitive_type)]) @completeFunction
