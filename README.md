# SOUNDBOARD

SOUNDBOARD is a simple soundboard app that records sound snippets and displays them in a grid with the ability to play them with a simple press.

To delete a snippet, do a long press on it. You can also use the action button in the app bar to clear the board.

## Instructions

This application targets Android and has only been tested on Android.
`getExternalStorageDirectory()` from the `path_provider` package is used and is not supported on iOS.

When recording for the first time, the application will ask for permissions to record audio and access files in storage.
After granting these permissions, in order to record, the FAB should be pressed again.

## Author

[Ignacio Echeverría](https://github.com/ignaeche)

## Assets

* [Majör Mono Display](https://fonts.google.com/specimen/Major+Mono+Display), licensed under OFL v1.1

## License

[MIT License](LICENSE)