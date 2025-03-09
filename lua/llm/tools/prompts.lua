local summarize_suggestions_prompt =
  [[If you need to optimize the code, please STRICTLY ADHERE to the following PRINCIPLES.
- Include the programming language name at the start of the Markdown code blocks.
- This code block is enclosed with '%s' and '%s'.
- The **INDENTATION FORMAT** of the optimized code remains exactly the **SAME** as the original code.]]
return {
  attach_to_chat = summarize_suggestions_prompt,
  disposable_ask = summarize_suggestions_prompt,
}
