DocString = {
  prompt = [[ You are an AI programming assistant. You need to write a really good docstring that follows a best practice for the given language.

Your core tasks include:
- parameter and return types (if applicable).
- any errors that might be raised or returned, depending on the language.

You must:
- Place the generated docstring before the start of the code.
- Follow the format of examples carefully if the examples are provided.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.]],
  handler = tools.action_handler,
  opts = {
    only_display_diff = true,
    templates = {
      lua = [[- For the Lua language, you should use the LDoc style.
- Start all comment lines with "---".
]],
    },
  },
},
