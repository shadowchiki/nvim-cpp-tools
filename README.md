# Nvim-Cpp-Tools

Nvim-Cpp-Tools is a plugin to give more functionality than Clangd can do natively
With this Plugin you can auto generate .cpp imeplementation from a .hpp, hxx, h file
Remove unused includes
This plugin is developed using [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

## Index

1. [Requirements](#requirements)
2. [Configure](#configure)
3. [Commands](#commands)
4. [Default keymaps](#default-keymaps)
5. [Future features](#future-features)

## Requirements

## Configure

Configuration with Lua

### LazyVim Configuration

```lua
{
 "shadowchiki/nvim-cpp-tools",
 dependencies = {
  "nvim-treesitter/nvim-treesitter",
 },
 config = function()
  require("nvim-cpp-tools")
 end,
}
```

## Commands

| Name                           | Description                                                                    | Command                       |
| ------------------------------ | ------------------------------------------------------------------------------ | ----------------------------- |
| Remove Unused Includes         | Remove the unsued includes detected in a file                                  | :RemoveUnusedIncludes         |
| Generate Cpp Implementation    | Creates a complete implementation of a header file to a implementation file    | :GenerateCppImplementation    |
| Generate Method Implementation | Creates a implementation of a method from header file to a implementation file | :GenerateMethodImplementation |

## Default keymaps

| Keymap     | Command                       |
| ---------- | ----------------------------- |
| <leader>co | :RemoveUnusedIncludes         |
| <leader>ci | :GenerateCppImplementation    |
| <leader>cI | :GenerateMethodImplementation |

## Future Features
