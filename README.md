# orion

## Specifications

Create a simple macOS app called Orion using Swift and AppKit. The app UI will contain only a WebView, the address (URL) bar, a back button and the “+” for new tab functionality. Entering a URL in the address should open the URL in the webview.

- For this project you will download and compile WebKit and then use the compiled version to provide the WebView in your project.
- When this browser visits: https://addons.mozilla.org/en-US/firefox/addon/top-sites-button/
    - “Add to Firefox” button on the page should change to “Add to Orion”.
- The user should be able to directly install the extension from the web page by clicking the “Add to Orion” button (as if the user is visiting it from a Firefox browser). You can check how real Orion browser does it for reference (download Orion at https://browser.kagi.com)
- Your app will then handle downloading and ‘installing’ the extension by unpacking and processing the extension package. The installed extension will be visible in the browser as a button on the toolbar.
- Implement support for topSites javascript web extension API that this extension uses. Clicking the toolbar button will render the extension output as in Firefox (basically it will show the list of top sites you visited in a HTML rendered popup).
- Implement a custom WebKit navigation delegate method which will be fired every time when navigation changes (including manipulated navigation through History API). For example, addons.mozilla.org uses the history API to manipulate the current URL to navigate internal pages, which isn’t supported by the existing "decidePolicyFor navigationAction" delegate method.
- Use that custom navigation delegate method to make sure all navigated URLs are served for topSites API.
