local summarize_suggestions_prompt =
  [[- When the user provides code, analyze it to determine if optimizations are possible (e.g., efficiency, readability, simplicity, or potential errors). If optimizations are needed, reply strictly in the following FORMAT:
%s
```<language>
<content>
```
%s
Replace <language> with the code’s language (e.g., python) and <content> with the optimized code.

- The **INDENTATION FORMAT** of the optimized code remains exactly the **SAME** as the original code.

- You may explain the reasons for such optimization appropriately, unless the user requests otherwise.

- All non-code text responses must be written in the %s language indicated.]]
return {
  attach_to_chat = summarize_suggestions_prompt,
  disposable_ask = summarize_suggestions_prompt,
}
