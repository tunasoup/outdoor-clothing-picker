# Outdoor Clothing Picker

Flutter project for choosing personal clothing (layers) based on weather and activity conditions.

Developed mainly for Android, partly web, iOS untested.

## Usage

To use automatic weather data, a personal API key (free, registration requirement) is needed from
[OpenWeatherMap](https://openweathermap.org/api). Manual weather information can also be provided.

The app allows the user to add their own activities, categories, and clothing. The clothing are
filtered according to the weather and selected activity to show a fitting item for each
available category. The categories are defined by the user, and given a location on a human
figure for visual purposes, and could be for example "Head", "Legs" or "Hands".

Clothing can be created without a referenced category or activities, but then they will be
filtered out. The clothing items can be edited in a separate screen after creation.

An empty temperature field is regarded as (negative) infinity. E.g., a "Jacket" with an empty 
minimum temperature and maximum temperature of 10 could be visualized with an active temperature 
anywhere between 10°C and -infinity (-273°C). Currently, the only supported temperature metric 
is Celsius.

## Installation

Install [Flutter](https://docs.flutter.dev/install). Tested on verion 3.35.1.

After platform specific installation (see below), build with
``dart run build_runner build`` and run with ``flutter run`` and choose the target device.

### Android

After installing Flutter, follow the instructions
[here](https://docs.flutter.dev/platform-integration/android/setup).
Developed with Android SDK Platform-tools version 36.0.0, tested on emulated Android device with
API level 31.

### Web

For web, download ``sqlite3.wasm`` and ``drift_worker.js``
to the ``web/`` subdirectory, following the
instruction [here](https://drift.simonbinder.eu/platforms/web/#prerequisites).
For (semi-)persistent data on web, use the same port (e.g., --web-port=3363)
and browser instance.
