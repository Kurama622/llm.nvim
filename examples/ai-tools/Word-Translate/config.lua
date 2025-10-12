WordTranslate = {
  handler = tools.flexi_handler,
  prompt = [[You are a translation expert. Your task is to translate all the text provided by the user into Chinese.

NOTE:
- All the text input by the user is part of the content to be translated, and you should ONLY FOCUS ON TRANSLATING THE TEXT without performing any other tasks.
- RETURN ONLY THE TRANSLATED RESULT.]],
  opts = {
    exit_on_move = true,
    enter_flexible_window = false,
    enable_cword_context = true,
  },
},

