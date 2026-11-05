# SimranK-DM-Portfolio

Quarto portfolio for M10. Includes four navigation pages, portrait, CSS, SCSS, a real Quarto dashboard, a working metadata-based listing, a submission report, and GitHub Pages workflow.

## Preview in Positron
1. Extract the ZIP. Copy the contents into your existing project folder if needed; preserve its .git folder. Do not create a nested project folder.
2. Open the folder containing _quarto.yml.
3. Run `quarto preview` in the terminal.
4. Check the four navigation tabs and portrait.
5. Run `quarto render` to create the HTML site in _site/.

## Publish to GitHub Pages
1. Commit and push the extracted files to the main branch of https://github.com/Simrank-DM/SimranK-DM-Portfolio. Include .github/workflows/publish.yml.
2. On GitHub open Settings > Pages. Choose GitHub Actions as the source.
3. Open Actions > Publish Quarto Portfolio > Run workflow if it has not run successfully automatically.
4. Check the successful deployment at https://Simrank-DM.github.io/SimranK-DM-Portfolio/.
5. Verify all tabs, photo, listing links, filters, and mobile layout on the published site.

## Before submission
- Dashboard: replace the overview-only status with verified project data and meaningful result visualizations when available. No numerical findings have been invented. Case 31 can be used instead if its data are supplied.
- Confirm biography and education details.
- Confirm the published website and repository links work and all source files are uploaded.
- Update submission.qmd's publication-status sentence after verifying deployment.
- Render the project and submit submission.qmd and _site/submission.html as directed by your instructor.

## Verification limits
This package was checked for file consistency, YAML parsing, relative paths, and ZIP integrity. Quarto is not installed in the preparation environment, so the site has not been rendered or visually tested here. It has not been uploaded to your GitHub repository or deployed.
