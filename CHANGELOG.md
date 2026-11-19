## 0.3.0

- Breaking: moved from `package:flutter/material.dart` to `package:material_ui/material_ui.dart` (Flutter 3.50 deprecates the Material library in the SDK). Requires Flutter 3.50 or newer and `material_ui` in the app. Apps still on `package:flutter/material.dart` must stay on 0.2.x, because the Material widgets and `Theme` of the two libraries are different classes.

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
