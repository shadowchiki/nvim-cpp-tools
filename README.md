# Nvim-Cpp-Tools

Nvim-Cpp-Tools is a plugin to give more functionality than Clangd can do natively
With this Plugin you can auto generate .cpp imeplementation from a .hpp, hxx, h file
Remove unused includes.
This plugin is developed using [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

## Index

1. [Requirements](#requirements)
2. [Configure](#configure)
3. [Commands](#commands)
4. [Default keymaps](#default-keymaps)
5. [Examples](#examples)
6. [Known Bugs](#known-bugs)

## Requirements

These are the requirements of the functionalities that I would like the plugin to have
This is what i expect, if you have some suggestion contact me via mail.

### General Requirements

- [x] Must be able to remove unused includes.

### Auto generate implementations of header file

- [ ] Must be able to allow to implement the inheritance methods that could have override the pure virtual parent methods.
- [x] Read attributes and set them to be automatically initialized in the constructor as if it had a parent.
- [ ] Template classes
- [ ] Ask you in which path you want to create the file.
- [x] Initialize the attributes of the class with the parameters of the constructor, the search must be by type, if there are several parameters of that type, make a comparison by name, if it does not contain the text, the first attribute found of the same type is put.
- [ ] Generate getters and setters
- [x] Select a method and generate it.
- [ ] Regenerate all Constructors
- [ ] Regenerate a single Constructor

### Refactoring requirements

- [ ] Allows to select a method and generate a local variable or attribute from the return of the function.
- [ ] Allows to mark (v) a block of code and export it in a function intuiting what kind of return is needed.
- [ ] It must allow that if a method returns a variable, it allows to generate a variable of the return type with a default name.
- [ ] The plugin must be able to refactor a class, change any comment of the class and put the new name in all the classes that use it.

## Configure

### LazyVim

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

| Keymap           | Command                       |
| ---------------- | ----------------------------- |
| &lt;leader&gt;co | :RemoveUnusedIncludes         |
| &lt;leader&gt;ci | :GenerateCppImplementation    |
| &lt;leader&gt;cI | :GenerateMethodImplementation |

## Examples

## Known bugs

- [ ] When try to generate a method with override, the implementation get override mark too
