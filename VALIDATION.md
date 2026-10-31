# Verification record

Completed on 27 October 2026.

- Julia 1.13.1; no external Julia packages required.
- 1,925 automated checks passed. See `results/test_summary.txt`.
- The full experiment completed 560,000 fixation-or-loss simulations across 28 conditions, with 20,000 repetitions per condition.
- Exact fixation probabilities agree with an independent numerical solution of the backward recurrence.
- Neutrality, absorbing boundaries, event probabilities, numerical stability, deterministic drift, seeds and Wilson intervals were checked.
- 27 of 28 nominal 95% intervals contain their exact probabilities. The retained miss is discussed in Chapter 9.
- All five code listings in the self-contained LaTeX project match their runnable originals byte-for-byte.
- LaTeX compilation succeeded with Tectonic; the desktop LaTeX editor also compiled the project successfully.
- The final PDF has 99 pages. All pages were reviewed as rendered contact sheets; equations, code and all three figures received closer inspection. Figure label spacing was corrected after that review.
- No overfull boxes, missing glyphs, unresolved references or page-edge text clipping remain.
- The PDF and all source, data, metadata and instructions are included in the project ZIP.

PDF SHA-256: `94e22e0137b0d8ef111b169a790dd8cebf42a0b36160b6352dad85cd08a5adc6`
