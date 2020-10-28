import Foundation

/**
 Interfaces generates an object type as well as possible type extensions.
 */

extension GraphQLCodegen {
    /// Generates a function to handle a type.
    func generateInterface(
        _ type: GraphQL.InterfaceType,
        with objects: [GraphQL.ObjectType]
    ) throws -> [String] {
        let name = type.name.pascalCase
        
        /* Collect of all fields of all possible types. */
        var fields: [GraphQL.Field] = type.fields
        for object in objects {
            // Skip object if it's not inside possible types.
            guard type.possibleTypes.contains(where: { $0.namedType.name == object.name }) else { continue }
            // Append fields otherwise.
            for field in object.fields {
                // Make suer fields are unique.
                guard !fields.contains(where: { $0.name == field.name }) else { continue }
                fields.append(field)
            }
        }
        
        /* Code */
        
        var code: [String] = [
            "/* \(type.name) */",
            "",
            "extension Interfaces {",
            "    struct \(name): Codable {",
            "        let __typename: TypeName",
        ]
        code.append(contentsOf: try fields.map { try generateFieldDecoder(for: $0) }.indent(by: 8))
        code.append(contentsOf: [
            "",
            "enum TypeName: String, Codable {".indent(by: 8),
        ])
        code.append(contentsOf: type.possibleTypes.map { "case \($0.namedType.name.camelCase) = \"\($0.namedType.name)\"" }.indent(by: 12))
        code.append(contentsOf: [
            "        }",
            "    }",
            "}",
            "",
            "extension SelectionSet where TypeLock == Interfaces.\(name) {",
        ])
        code.append(contentsOf:  try type.fields.flatMap { try generateField($0) }.indent(by: 4))
        code.append(contentsOf: [
            "}",
            "",
        ])
        code.append(contentsOf: generateFragmentSelection("Interfaces.\(type.name.pascalCase)", for: type.possibleTypes, with: objects))
        
        return code
    }
}