# My Fitness Tracker

Offline-first, mobile-focused personal fitness PWA. The repository began empty, so the app uses plain JavaScript, HTML and CSS without a package manager, framework, build step, external service, or credentials.

## Run locally

Use a local HTTP server (service workers require localhost or HTTPS):

```sh
python3 -m http.server 8000
```

Open `http://localhost:8000` in a browser. No install step or environment variables are required.

## Deploy

Publish the repository root as a static site on any HTTPS static host (for example, GitHub Pages, Netlify, or Cloudflare Pages). Set the publish directory to the repository root. There is no backend or database migration. Make sure the host serves `manifest.webmanifest` and `sw.js` from the same origin and does not rewrite those paths to an HTML 404 page. The service worker caches the app shell and updates its versioned cache when the shell changes.

For GitHub Pages, push this folder to a repository, then choose **Settings → Pages → Deploy from a branch**, select the branch and `/ (root)`, and wait for the HTTPS URL to become available. Then open that URL in iPhone Safari, tap **Share → Add to Home Screen → Add**. This adds the web app to the Home Screen; it does not create an App Store application.

## Storage and privacy

The app stores one versioned state record in IndexedDB on the device, with localStorage as a browser fallback. It includes profile settings, daily logs, meal edits and notes, workouts, and measurements. There is no account, server sync, or remote data transfer. Use **Settings → Export backup** regularly; restore replaces the current local data. Clearing site data or removing browser storage can erase records.

## Current scope and limitations

- The complete initial seven-day vegetarian meal list and specified gym routines are bundled. Meal names, ingredients, quantities and notes can be edited and are persisted. Actual consumed calories and protein can be entered manually.
- The tracker deliberately does **not** calculate meal calories/macros: verified item-level nutrient data (including brand-specific paneer, whey, preparation and cooked yields) is not bundled. It does not present guessed values as accurate.
- Workout weights, actual reps, set completion, notes, a 90-second rest timer, history and confirm-before-using overload suggestions are available. No weight is changed automatically.
- Service-worker offline shell caching and local offline records are implemented. Browser notifications only request permission; reliable scheduled/background reminders are not implemented. iOS web push/background behavior varies by version and installation mode.
- The app has not been tested on a physical iPhone or deployed from this workspace. HTTPS hosting is required for service workers outside localhost. No browser automation runtime or deployment credentials were present.

## Native iPhone app

An initial SwiftUI iOS app project is in `ios/MyFitnessTracker.xcodeproj`. It keeps profile, checklist, meals, workouts, and measurements in the app's local UserDefaults store. No web hosting is needed for this native target. To install it, open the project in Xcode, connect and trust the iPhone, select the phone as the run destination, set a signing team under **Signing & Capabilities**, then press **Run**. Xcode on this Mac has not yet had its Apple SDK licence accepted, so an Xcode build/install has not been completed. The Swift source passed iOS-target type checking; a full build and device QA remain pending.
