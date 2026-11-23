# markdown-protocol

A CommonMark-subset markdown parser for [cl-stack](https://github.com/egao1980/cl-stack), with GFM tables and `~~strike~~`. It returns a plain-list AST of blocks and inlines that compares with `EQUAL`. It has no dependencies.

Brief: [`cl-stack/docs/capabilities/markdown.md`](https://github.com/egao1980/cl-stack/blob/main/docs/capabilities/markdown.md).

| Consumer | Use |
|----------|-----|
| [`tui-markdown`](https://github.com/egao1980/tui-markdown) | renders the AST as styled terminal lines (re-exports `parse-markdown`) |
| [`doc-extract-protocol`](https://github.com/egao1980/doc-extract-protocol) | `parse-markup` maps the AST onto the extracted-document model |

```lisp
(asdf:load-system "markdown-protocol")

(stack-markdown:parse-markdown "# Hi
Some *emphasis* and [a link](https://example.com).")
;; → ((:heading 1 ("Hi"))
;;    (:paragraph ("Some " (:emph ("emphasis")) " and "
;;                 (:link "https://example.com" ("a link")) ".")))
```

## API

| Function | Result |
|----------|--------|
| `(parse-markdown string)` | list of blocks |
| `(parse-markdown-document string)` | `(values blocks open-fence)`: OPEN-FENCE is `(char . length)` when a top-level fenced code block runs unclosed to the end, for streaming readers |

A non-string signals `type-error`. Any string parses; text the subset does not cover stays text.

## AST

```text
Blocks:  (:paragraph inlines)  (:heading level inlines)  (:thematic-break)
         (:code-block language lines)                ; language: string or NIL
         (:block-quote blocks)
         (:bullet-list tight items)                  ; items: list of block lists
         (:ordered-list start delimiter tight items) ; delimiter #\. or #\)
         (:table alignments header rows)             ; :left :right :center NIL;
                                                     ; a cell is a list of inlines
Inlines: string  (:emph inlines)  (:strong inlines)  (:strike inlines)
         (:code string)  (:link url inlines)  (:image url alt-inlines)
         (:soft-break)  (:hard-break)
```

Adjacent strings are merged and empty strings are dropped.

## Subset

CommonMark 0.31 blocks (ATX headings, thematic breaks, fenced code, block quotes, bullet and ordered lists with tight/loose) and inlines (backslash escapes, code spans, `*`/`_` emphasis with the delimiter-run algorithm, inline links, images, autolinks, hard and soft breaks), plus GFM tables and `~~strike~~`. Not supported, so left as text: lazy continuation lines, setext headings, indented code blocks, HTML, link reference definitions, entities, footnotes, task-list markers and math. Without lazy lines, setext headings or reference definitions, a later line never changes an earlier block, so a stream can commit completed blocks. The exact rules are in the header of [`src/markdown.lisp`](src/markdown.lisp).

## Tests

```sh
cl-repo test --system markdown-protocol
```

## License

MIT. See [LICENSE](LICENSE).
