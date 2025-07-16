local generate_cpp_file = require("generate_cpp_file")

describe("generate_cpp_file", function()
	local original_get_parser, original_ts_query_get, original_get_node_text

	before_each(function()
		original_get_parser = vim.treesitter.get_parser
		original_ts_query_get = vim.treesitter.query.get
		original_get_node_text = vim.treesitter.get_node_text
	end)

	after_each(function()
		vim.treesitter.get_parser = original_get_parser
		vim.treesitter.query.get = original_ts_query_get
		vim.treesitter.get_node_text = original_get_node_text
	end)

	it("create_simple_implementation_with_default_config", function()
		local hpp_path = vim.fn.getcwd() .. "/test/testingfiles/TestingClass.hpp"
		vim.cmd("e " .. hpp_path)

		local buf = vim.api.nvim_get_current_buf()
		assert.equals("cpp", vim.bo[buf].filetype)

		vim.treesitter.get_parser = function(_, _)
			return {
				parse = function()
					return {
						{
							root = function()
								return "FAKE_ROOT"
							end,
						},
					}
				end,
			}
		end

		vim.treesitter.query.get = function(lang, _)
			assert.equals("cpp", lang)
			return {
				captures = {
					"namespace",
					"className",
					"constructorParamList",
					"constructorParamList",
					"methodLine",
					"methodType",
					"methodName",
					"methodNameRemove",
					"virtual",
					"methodLine",
					"methodType",
					"methodName",
					"attributeType",
					"attributeName",
				},
				iter_captures = function(_, _)
					local i = 0
					local fake_nodes = {
						-- { id, node }
						{
							1,
							{
								range = function()
									return 0, 0, 0, 12
								end,
								type = function()
									return "namespace"
								end,
								_text = "testing::name",
							},
						},
						{
							2,
							{
								range = function()
									return 1, 0, 1, 12
								end,
								type = function()
									return "className"
								end,
								_text = "TestingClass",
							},
						},
						{
							3,
							{
								range = function()
									return 2, 0, 2, 2
								end,
								type = function()
									return "constructorParamList"
								end,
								_text = "()",
							},
						},
						{
							4,
							{
								range = function()
									return 3, 0, 3, 18
								end,
								type = function()
									return "constructorParamList"
								end,
								_text = "(std::string value)",
							},
						},
						{
							5,
							{
								range = function()
									return 4, 0, 4, 36
								end,
								type = function()
									return "methodLine"
								end,
								_text = "virtual std::string virtualMethod() = 0;",
							},
						},
						{
							6,
							{
								range = function()
									return 5, 0, 5, 10
								end,
								type = function()
									return "methodType"
								end,
								_text = "std::string",
							},
						},
						{
							7,
							{
								range = function()
									return 5, 12, 5, 26
								end,
								type = function()
									return "methodName"
								end,
								_text = "virtualMethod()",
							},
						},
						{
							8,
							{
								range = function()
									return 5, 12, 5, 26
								end,
								type = function()
									return "methodNameRemove"
								end,
								_text = "virtualMethod()",
							},
						},
						{
							9,
							{
								range = function()
									return 5, 27, 5, 28
								end,
								type = function()
									return "virtual"
								end,
								_text = "0",
							},
						},
						{
							10,
							{
								range = function()
									return 6, 0, 6, 36
								end,
								type = function()
									return "methodLine"
								end,
								_text = "virtual int& method1(std::string value);",
							},
						},
						{
							11,
							{
								range = function()
									return 7, 0, 7, 10
								end,
								type = function()
									return "methodType"
								end,
								_text = "int",
							},
						},
						{
							12,
							{
								range = function()
									return 7, 11, 7, 32
								end,
								type = function()
									return "methodName"
								end,
								_text = "& method1(std::string value)",
							},
						},
						{
							13,
							{
								range = function()
									return 8, 0, 8, 12
								end,
								type = function()
									return "attributeType"
								end,
								_text = "std::string",
							},
						},
						{
							14,
							{
								range = function()
									return 8, 13, 8, 18
								end,
								type = function()
									return "attributeName"
								end,
								_text = "value",
							},
						},
					}

					return function()
						i = i + 1
						local pair = fake_nodes[i]
						if pair then
							return unpack(pair)
						end
					end
				end,
			}
		end

		vim.treesitter.get_node_text = function(node, _)
			return node._text
		end

		generate_cpp_file.generate_cpp_file()

		local lines_created = {}
		local lines_expected = {}

		local created_file_path = vim.fn.getcwd() .. "/test/testingfiles/TestingClass.cpp"
		local expected_file_path = vim.fn.getcwd() .. "/test/expectedfiles/TestingClass.cpp"

		local file = io.open(created_file_path, "r")
		local expected_file = io.open(expected_file_path, "r")

		if not file then
			vim.notify("No se pudo abrir el archivo: ", vim.log.levels.ERROR)
			return nil
		end

		for line in file:lines() do
			table.insert(lines_created, line)
		end
		for line in expected_file:lines() do
			table.insert(lines_expected, line)
		end

		assert.are.same(lines_created, lines_expected)

		io.close(file)
		io.close(expected_file)
		os.remove(created_file_path)
	end)
end)
