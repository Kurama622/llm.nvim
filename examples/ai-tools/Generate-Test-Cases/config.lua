TestCode = {
  handler = tools.side_by_side_handler,
  prompt = [[ Write some test cases for the following code, only return the test cases.
Give the code content directly, do not use code blocks or other tags to wrap it. ]],
  opts = {
    right = {
      title = " Test Cases ",
    },
  },
},
