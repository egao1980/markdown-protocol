(in-package #:markdown-protocol)

;;; ------------------------------------------------------------------
;;; Markdown: a CommonMark 0.31 subset plus GFM tables and ~~strike~~.
;;; Where this header and CommonMark differ, this header wins. The brief
;;; (cl-stack docs/capabilities/markdown.md) has the same rules with
;;; reasons.
;;;
;;; BLOCKS (line based; a container takes its lines, strips its marker or
;;; indentation and parses the rest recursively):
;;;  - Lines split at LF; one CR before it is dropped. Tabs in a line's
;;;    leading whitespace become spaces (4-column stops), also inside
;;;    fenced code. Block starts allow 0–3 spaces of indent.
;;;  - ATX headings: 1–6 #, then a space/tab or the end of the line. An
;;;    optional closing run of # preceded by a space is dropped. No setext
;;;    headings: "---" under a paragraph is a thematic break.
;;;  - Thematic break: 3+ of one of * - _ with optional spaces/tabs.
;;;  - Fenced code: 3+ ` or ~; a backtick fence's info may not contain `.
;;;    Language = first word of the info string, NIL if none. Closed by the
;;;    same character, at least as many, 0–3 spaces of indent, only
;;;    whitespace after; unclosed runs to the end of its container. Up to
;;;    the opening fence's indent is removed from each content line.
;;;  - Block quote: ">" plus one optional space; consecutive ">" lines.
;;;    No lazy continuation.
;;;  - Lists: bullets - + *, ordered 1–9 digits then . or ). The content
;;;    column is the marker end plus 1–4 spaces (1 when 5+ spaces follow
;;;    or the rest is blank). Following lines indented to the content
;;;    column belong to the item; blank lines belong when the next
;;;    non-blank line is indented that far. An item may start with one
;;;    blank line only. No lazy continuation. A different bullet character
;;;    or ordered delimiter starts a new list; the first number is the
;;;    start. A thematic break wins over a list item. Loose when items are
;;;    separated by blank lines or an item holds two blocks with a blank
;;;    line between them.
;;;  - Tables (GFM): a line with "|" (0–3 indent, not inside a paragraph)
;;;    followed by a delimiter row (cells :?-+:? split at "|") with the
;;;    same cell count. Rows run to a blank line or a line that would
;;;    interrupt a paragraph; each row is padded / cut to the header's
;;;    count. Cells: outer pipes dropped, split at unescaped "|", "\|" → "|",
;;;    trimmed, parsed inline.
;;;  - Paragraphs: other lines, until a blank line or an interrupting line:
;;;    a heading, fence, block quote, thematic break, non-empty bullet item
;;;    or non-empty ordered item starting at 1 — at most 3 spaces of
;;;    indent. Continuation lines lose their leading whitespace; the
;;;    paragraph's trailing whitespace is dropped.
;;;  - Not supported (left as text): indented code blocks, setext headings,
;;;    HTML blocks, link reference definitions, footnotes, task-list
;;;    markers, math.
;;;
;;; INLINES (CommonMark §6 with its delimiter-run algorithm):
;;;  - Backslash escapes of ASCII punctuation; backslash + newline is a
;;;    hard break; other backslashes are text.
;;;  - Code spans: equal-length backtick strings; newlines → spaces; one
;;;    space stripped from each end when both are spaces and the content
;;;    is not all spaces. Unmatched backticks are text.
;;;  - Emphasis * and _ with left/right-flanking runs, the intraword _
;;;    rule and the multiple-of-3 rule; *** → (:emph ((:strong …))).
;;;    ~~ (exactly two) → :strike under the same flanking rules.
;;;  - Inline links [text](dest "title"): dest bare (balanced parens,
;;;    escapes) or <…>; title dropped; no links inside links; emphasis is
;;;    resolved inside the brackets first. Autolinks <scheme:…> (scheme
;;;    2–32 chars) → (:link url (url)). No reference links, no images
;;;    ("!" stays text), no raw HTML (text), no entities (text).
;;;  - Newline → (:soft-break); two or more spaces before it → (:hard-break).
;;;    Spaces around a newline are dropped.

(defun parse-markdown-document (string)
  "Parse STRING like PARSE-MARKDOWN. → (values blocks open-fence).
OPEN-FENCE is (char . length) when a top-level fenced code block runs
unclosed to the end of STRING, else NIL: a streaming reader uses it to tell
a partial closing fence from text. A non-string → TYPE-ERROR."
  (check-type string string)
  (let ((*open-fence* nil)
        (*depth* 0))
    (let ((blocks (values (%parse-blocks (%source-lines string)))))
      (values blocks *open-fence*))))

(defun parse-markdown (string)
  "Parse STRING (the subset above) → a list of blocks. A non-string →
TYPE-ERROR. Never signals on any string.

Blocks:  (:paragraph inlines) (:heading level inlines) (:thematic-break)
         (:code-block language lines)       ; language: string or NIL
         (:block-quote blocks)
         (:bullet-list tight items)          ; items: list of block lists
         (:ordered-list start delimiter tight items)   ; delimiter #\\. or #\\)
         (:table alignments header rows)     ; alignment :left :right :center NIL;
                                             ; header: cells; rows: lists of cells;
                                             ; a cell is a list of inlines
Inlines: string  (:emph inlines) (:strong inlines) (:strike inlines)
         (:code string) (:link url inlines) (:soft-break) (:hard-break)
Adjacent strings are merged and empty strings dropped, so results compare
with EQUAL."
  (check-type string string)
  (values (parse-markdown-document string)))
