## 0.2.1

- Documentation: full API docs, a rewritten README with demo GIFs, screenshots on pub.dev.
- No code changes.

## 0.2.0

- `ArrowRingStyle`: arrow color, ring color, label color, label background pill, label text style, arrow size, ring width and padding, hop distance and the up and down icons can all be changed. `ArrowRing` takes it as `style`, `TourOverlay` as `arrowStyle`. Breaking: `ArrowRing.color` and `ArrowRing.hopDistance` moved into the style.
- `TourCard.color` and `TourCard.elevation`. The default color is now `surfaceContainerHigh` (one step lighter than the page) instead of `surface`, so the card stands out in dark mode. Pass `color: Theme.of(context).colorScheme.surface` for the old look.
- `TourCard`: title, progress and text scroll together when the card is short (landscape, large system font); the buttons stay in view.
- `TourController.clock`: inject the time source of the tap guard, so tests do not have to wait in real time.

## 0.1.0

- `ArrowRing`, `TourCard`, `TourOverlay`, `TourController`, `TourStep`, `TourStorage`.
