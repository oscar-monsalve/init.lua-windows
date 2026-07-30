return {
    "mzlogin/vim-markdown-toc",
    ft = "markdown",
    -- :GenTocGFM generates a GitHub-flavored Markdown TOC at the cursor.
    -- :GenTocGitLab generates a GitLab-compatible Markdown TOC.
    -- :GenTocMarked generates a TOC compatible with marked/markdown-preview.
    -- :GenTocRedcarpet generates a Redcarpet-compatible Markdown TOC.
    -- :UpdateToc updates an existing fenced TOC when auto-update is disabled.
    -- :RemoveToc removes an existing fenced TOC.
    -- :TocGoto jumps to the heading referenced by the TOC entry under the cursor.
    --
    -- For GitHub Markdown, use :GenTocGFM; existing fenced TOCs update on :w by default.
    cmd = {
        "GenTocGFM",
        "GenTocGitLab",
        "GenTocMarked",
        "GenTocRedcarpet",
        "RemoveToc",
        "TocGoto",
        "UpdateToc",
    },
}
