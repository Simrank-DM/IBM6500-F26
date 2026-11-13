# M10 Quarto website

1. Open this extracted M10 folder in Positron or RStudio. Use Quarto 1.4 or newer for dashboards.
2. Preview the portrait on the Home page.
3. Review the CEP overview against your latest project decisions.
4. In the terminal, run `quarto preview` to inspect the website.
5. Run `quarto render` to generate the site in docs/.
6. Push the entire M10 folder, including source files and generated docs/, to GitHub.
7. For easiest GitHub Pages setup, put the CONTENTS of M10 at the root of a dedicated repository. In Settings > Pages, choose Deploy from a branch, your main branch, and /docs. A nested M10/docs folder cannot be selected as the Pages branch source. Alternatively publish with `quarto publish gh-pages` from M10.
8. Add the actual published website and repository links to M10-Submission-Simran-Kaur.qmd, then render again.
9. Submit the submission QMD and its rendered HTML.

The source is provided without rendered HTML: Quarto is not installed in the preparation environment. No code packages or data files are needed. Dashboard content is a project overview, with no invented validation results.
